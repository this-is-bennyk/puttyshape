@tool
@icon("res://putty_shape/icons/putty_container_3D.svg")
class_name PuttyContainer3D
extends MeshInstance3D

## Creates a 3D mesh out of [PuttyShape3D]s and their properties.
## 
## The [PuttyContainer3D] is a specialized [MeshInstance3D] that renders
## child [PuttyShape3D]s by using their corresponding [b]signed distance
## field[/b] ([b]SDF[/b]) functions to determine which points in a voxel
## area are inside the shapes, and then using those found points to construct
## a mesh using the [b]naive surface nets[/b] algorithm. This is done with a
## compute shader on a separate thread to calculate and build a [Mesh] as quickly
## as reasonably possible.[br]
## [b][u]WARNING[/u][/b]: This node is currently [b][u][i]NOT[/i][/u][/b]
## intended for real-time release-build applications. This is meant to be
## an in-editor solution for building static meshes (or meshes to be rigged
## in a separate program) directly inside Godot. Large Putty shapes will
## slow down the editor. There are no guarantees that this node will work
## as expected in release mode on certain devices.

const PUTTY_SAMPLER_3D := preload("res://addons/putty_shape/datatypes/3d/PuttySampler3D.glsl")

@export_tool_button("Update")
var update_mesh := submit_request

@export
var sample_space := AABB(Vector3.ONE * -20.0, Vector3.ONE * 40.0)

var _sdf_samples := PackedFloat32Array()
var _vertices := PackedVector3Array()
var _triangles := PackedInt64Array()

var _cube_edges := PackedInt64Array()
var _edge_table := PackedInt64Array()

var _shapes: Array[PuttyShape3D] = []
var _dimensions := Vector3i()
var _transforms := PackedVector4Array()
var _minimum_scales := PackedFloat32Array()
var _shape_types := PackedInt32Array()
var _shape_params := PackedVector4Array()
var _combinations_types_and_params := PackedVector4Array()

var _resulting_mesh: ArrayMesh = null

var _rendering_device: RenderingDevice = null
var _sampler := RID()

var _mesh_thread := Thread.new()
var _last_request := 0
var _exiting := false

func _ready() -> void:
	var num_threads := maxi(1, OS.get_processor_count() - 2)
	
	_create_cube_edges_table()
	_create_intersection_table()
	
	_rendering_device = RenderingServer.create_local_rendering_device()
	_sampler = _rendering_device.shader_create_from_spirv(PUTTY_SAMPLER_3D.get_spirv())
	
	_last_request = Time.get_ticks_usec()
	_mesh_thread.start(_mesh_creation_loop)
	
	child_order_changed.connect(submit_request)

func submit_request() -> void:
	_last_request = Time.get_ticks_usec()

func _mesh_creation_loop() -> void:
	var _cur_request := _last_request
	
	while not _exiting:
		if _cur_request == _last_request:
			continue
		
		call_thread_safe(&"_create_mesh", _last_request)
	
		_cur_request = _last_request

func _exit_tree() -> void:
	_exiting = true
	_mesh_thread.wait_to_finish()
	_rendering_device.free_rid(_sampler)

func _get_shapes() -> void:
	_shapes.clear()
	
	for child: Node in get_children():
		if child is not PuttyShape3D:
			continue
		
		_shapes.push_back(child as PuttyShape3D)

func _create_mesh(request: int) -> void:
	_resulting_mesh = null
	
	_vertices.clear()
	_triangles.clear()
	
	_get_shapes()
	
	if _shapes.size() <= 0:
		return
	
	if request != _last_request:
		return
	
	call_thread_safe(&"_gather_samples", request)
	
	if request != _last_request:
		return
	
	call_deferred(&"call_thread_safe", &"_compute_mesh", request)
	
	if request != _last_request:
		return
	
	call_deferred(&"call_deferred", &"call_thread_safe", &"_create_surface_mesh", request)
	
	if request != _last_request:
		return
	
	call_deferred(&"call_deferred", &"call_deferred", &"call_thread_safe", &"_add_mesh")

func _get_world_space_position(voxel_pos: Vector3i) -> Vector3:
	return sample_space.position + Vector3(
		float(voxel_pos.x) * sample_space.size.x / float(_dimensions.x),
		float(voxel_pos.y) * sample_space.size.y / float(_dimensions.y),
		float(voxel_pos.z) * sample_space.size.z / float(_dimensions.z)
	)

func _create_cube_edges_table() -> void:
	for i: int in 8:
		var j := 1
		
		while j <= 4:
			var p := i ^ j
			
			if i <= p:
				_cube_edges.append(i)
				_cube_edges.append(p)
			
			j <<= 1

func _create_intersection_table() -> void:
	for i: int in 256:
		var edge_mask := 0
		
		for j: int in range(0, 24, 2):
			var a := bool(i & (1 << _cube_edges[j]))
			var b := bool(i & (1 << _cube_edges[j + 1]))
			
			edge_mask |= (1 << (j >> 1)) if a != b else 0
		
		_edge_table.append(edge_mask)

func _gather_samples(request: int) -> void:
	_transforms.clear()
	_minimum_scales.clear()
	_shape_types.clear()
	_shape_params.clear()
	_combinations_types_and_params.clear()
	
	for shape: PuttyShape3D in _shapes:
		var inv_transform := shape.global_transform.affine_inverse()
		
		_transforms.append(Vector4(inv_transform.basis.x.x, inv_transform.basis.x.y, inv_transform.basis.x.z, 0.0))
		_transforms.append(Vector4(inv_transform.basis.y.x, inv_transform.basis.y.y, inv_transform.basis.y.z, 0.0))
		_transforms.append(Vector4(inv_transform.basis.z.x, inv_transform.basis.z.y, inv_transform.basis.z.z, 0.0))
		_transforms.append(Vector4(inv_transform.origin.x, inv_transform.origin.y, inv_transform.origin.z, 0.0))
		
		_minimum_scales.append(minf(shape.global_transform.basis.get_scale().x, minf(shape.global_transform.basis.get_scale().y, shape.global_transform.basis.get_scale().z)))
		
		_shape_types.append(shape.get_shape_type())
		
		_shape_params.append(shape.get_first_arguments())
		_shape_params.append(shape.get_second_arguments())
		
		_combinations_types_and_params.append(Vector4(float(int(shape.combination_type)), shape.combination_first_radius, shape.combination_second_radius, float(shape.combination_steps)))
	
	_dimensions = Vector3i(sample_space.size.ceil())
	
	var static_params_bytes := PackedByteArray()
	
	static_params_bytes.append_array(
		PackedFloat32Array([
			sample_space.position.x,
			sample_space.position.y,
			sample_space.position.z,
			NAN,
			
			sample_space.size.x,
			sample_space.size.y,
			sample_space.size.z,
			NAN,
			
			float(_dimensions.x),
			float(_dimensions.y),
			float(_dimensions.z),
			
		]).to_byte_array()
	)
	
	static_params_bytes.append_array(
		PackedInt32Array([
			_shapes.size(),
			
		]).to_byte_array()
	)
	
	var static_params_buffer := _rendering_device.storage_buffer_create(static_params_bytes.size(), static_params_bytes)
	var static_params_uniform := RDUniform.new()
	
	static_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	static_params_uniform.binding = 0
	static_params_uniform.add_id(static_params_buffer)
	
	var transforms_bytes := _transforms.to_byte_array()
	var transforms_buffer := _rendering_device.storage_buffer_create(transforms_bytes.size(), transforms_bytes)
	var transforms_uniform := RDUniform.new()
	
	transforms_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	transforms_uniform.binding = 1
	transforms_uniform.add_id(transforms_buffer)
	
	var minimum_scales_bytes := _minimum_scales.to_byte_array()
	var minimum_scales_buffer := _rendering_device.storage_buffer_create(minimum_scales_bytes.size(), minimum_scales_bytes)
	var minimum_scales_uniform := RDUniform.new()
	
	minimum_scales_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	minimum_scales_uniform.binding = 2
	minimum_scales_uniform.add_id(minimum_scales_buffer)
	
	var shape_types_bytes := _shape_types.to_byte_array()
	var shape_types_buffer := _rendering_device.storage_buffer_create(shape_types_bytes.size(), shape_types_bytes)
	var shape_types_uniform := RDUniform.new()
	
	shape_types_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	shape_types_uniform.binding = 3
	shape_types_uniform.add_id(shape_types_buffer)
	
	var shape_params_bytes := _shape_params.to_byte_array()
	var shape_params_buffer := _rendering_device.storage_buffer_create(shape_params_bytes.size(), shape_params_bytes)
	var shape_params_uniform := RDUniform.new()
	
	shape_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	shape_params_uniform.binding = 4
	shape_params_uniform.add_id(shape_params_buffer)
	
	var combinations_types_and_params_bytes := _combinations_types_and_params.to_byte_array()
	var combinations_types_and_params_buffer := _rendering_device.storage_buffer_create(combinations_types_and_params_bytes.size(), combinations_types_and_params_bytes)
	var combinations_types_and_params_uniform := RDUniform.new()
	
	combinations_types_and_params_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	combinations_types_and_params_uniform.binding = 5
	combinations_types_and_params_uniform.add_id(combinations_types_and_params_buffer)
	
	_sdf_samples = PackedFloat32Array()
	_sdf_samples.resize(_dimensions.x * _dimensions.y * _dimensions.z)
	_sdf_samples.fill(INF)
	
	var samples_bytes := _sdf_samples.to_byte_array()
	var samples_buffer := _rendering_device.storage_buffer_create(samples_bytes.size(), samples_bytes)
	var samples_uniform := RDUniform.new()
	
	samples_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	samples_uniform.binding = 6
	samples_uniform.add_id(samples_buffer)
	
	var uniform_set := _rendering_device.uniform_set_create(
		[
			static_params_uniform,
			transforms_uniform,
			minimum_scales_uniform,
			shape_types_uniform,
			shape_params_uniform,
			combinations_types_and_params_uniform,
			samples_uniform,
		],
		_sampler,
		0)
	
	var pipeline := _rendering_device.compute_pipeline_create(_sampler)
	var compute_list := _rendering_device.compute_list_begin()
	
	_rendering_device.compute_list_bind_compute_pipeline(compute_list, pipeline)
	_rendering_device.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	_rendering_device.compute_list_dispatch(compute_list, maxi(1, ceili(float(_dimensions.x) / 10.0)), maxi(1, ceili(float(_dimensions.y) / 10.0)), maxi(1, ceili(float(_dimensions.z) / 10.0)))
	
	_rendering_device.compute_list_end()
	
	_rendering_device.submit()
	_rendering_device.sync()
	
	_sdf_samples = _rendering_device.buffer_get_data(samples_buffer).to_float32_array()
	
	_rendering_device.free_rid(pipeline)
	_rendering_device.free_rid(samples_buffer)
	_rendering_device.free_rid(combinations_types_and_params_buffer)
	_rendering_device.free_rid(shape_params_buffer)
	_rendering_device.free_rid(shape_types_buffer)
	_rendering_device.free_rid(minimum_scales_buffer)
	_rendering_device.free_rid(transforms_buffer)
	_rendering_device.free_rid(static_params_buffer)

func _create_surface_mesh(request: int) -> void:
	if _vertices.size() < 3 or request != _last_request:
		return
	
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for vertex: Vector3 in _vertices:
		surface_tool.add_vertex(vertex)
	
	if request != _last_request:
		return
	
	for vertex_index: int in _triangles:
		surface_tool.add_index(vertex_index)
	
	if request != _last_request:
		return
	
	surface_tool.generate_normals()
	
	if request != _last_request:
		return
	
	surface_tool.optimize_indices_for_cache()
	
	if request != _last_request:
		return
	
	_resulting_mesh = surface_tool.commit()

func _add_mesh() -> void:
	if _resulting_mesh == null:
		return
	
	var shadow_mesh := _resulting_mesh.duplicate(true) as ArrayMesh
	_resulting_mesh.shadow_mesh = shadow_mesh
	
	mesh = _resulting_mesh

## From Mikola Lysenko's JS implementation of surface nets
## https://github.com/mikolalysenko/mikolalysenko.github.com/blob/master/Isosurface/js/surfacenets.js
## Licensed under the MIT License.
func _compute_mesh(request: int) -> void:
	var buffer := PackedInt64Array()
	buffer.resize(4096)
	
	var n := 0
	var R := Vector3i(1, _dimensions.x + 1, (_dimensions.x + 1) * (_dimensions.y + 1))
	var grid := PackedFloat64Array()
	var buffer_number := 1
	
	grid.resize(8)
	
	if R.z * 2 > buffer.size():
		buffer.resize(R.z * 2)
	
	for pos_z: int in _dimensions.z - 1:
		var buffer_index := 1 + (_dimensions.x + 1) * (1 + buffer_number * (_dimensions.y + 1))
		
		for pos_y: int in _dimensions.y - 1:
			for pos_x: int in _dimensions.x - 1:
				if request != _last_request:
					return
				
				var pos := Vector3i(pos_x, pos_y, pos_z)
				
				var mask := 0
				var grid_pos := 0
				var sample_index := n
				
				# Read in 8 SDF samples around this vertex and store them in an array
				# Also calculate 8-bit mask, like in marching cubes, so we can speed up sign checks later
				for k: int in 2:
					for j: int in 2:
						for i: int in 2:
							var sample := _sdf_samples[sample_index]
							grid[grid_pos] = sample
							mask |= (1 << grid_pos) if sample < 0.0 else 0
							
							grid_pos += 1
							sample_index += 1
							
						sample_index += _dimensions.x - 2
						
					sample_index += _dimensions.x * (_dimensions.y - 2)
				
				# Check for early termination if cell does not intersect boundary
				if mask == 0 or mask == 0xFF:
					# Inner loop iteration
					n += 1
					buffer_index += 1
					continue
				
				# Sum up edge intersections
				var edge_mask := _edge_table[mask]
				var vertex := Vector3()
				var edge_count := 0
				
				# For every edge of the cube...
				for i: int in 12:
					# Use edge mask to check if it is crossed
					if not bool(edge_mask & (1 << i)):
						continue
					
					# If it did, increment number of edge crossings
					edge_count += 1
					
					# Find the point of intersection
					
					# Unpack vertices
					var edge0 := _cube_edges[i << 1]
					var edge1 := _cube_edges[(i << 1) + 1]
					# Unpack grid values
					var grid0 := grid[edge0]
					var grid1 := grid[edge1]
					# Compute point of intersection
					var t := grid0 - grid1
					
					if absf(t) > 1e-6:
						t = grid0 / t
					else:
						continue
					
					# Interpolate vertices and add up intersections (this can be done without multiplying)
					var k := 1
					
					for j: int in 3:
						var a := edge0 & k
						var b := edge1 & k
						
						if a != b:
							vertex[j] += 1.0 - t if bool(a) else t
						else:
							vertex[j] += 1.0 if bool(a) else 0.0
						
						k <<= 1
				
				# Average the edge intersections and add them to the coordinate
				var s := 1.0 / float(edge_count)
				vertex = _get_world_space_position(pos) + s * vertex
				
				buffer[buffer_index] = _vertices.size()
				_vertices.append(vertex)
				#_vertices_sample_positions.append(Vector3(pos))
				
				# Add faces together by looping over the 3 basis components
				for i: int in 3:
					# The first three entries of the edge_mask count the crossings along the edge
					if not bool(edge_mask & (1 << i)):
						continue
					
					# i = axis pointing along; iu, iv = orthogonal axes
					var iu := (i + 1) % 3
					var iv := (i + 2) % 3
					
					# Skip if on a boundary
					if pos[iu] == 0 or pos[iv] == 0:
						continue
					
					# Otherwise look up adjacent edges in the buffer
					var du := R[iu]
					var dv := R[iv]
					
					# Flip orientation depending on the sign of the corner
					if bool(mask & 1):
						_triangles.push_back(buffer[buffer_index])
						_triangles.push_back(buffer[buffer_index - du - dv])
						_triangles.push_back(buffer[buffer_index - du])
						_triangles.push_back(buffer[buffer_index])
						_triangles.push_back(buffer[buffer_index - dv])
						_triangles.push_back(buffer[buffer_index - du - dv])
					else:
						_triangles.push_back(buffer[buffer_index])
						_triangles.push_back(buffer[buffer_index - du - dv])
						_triangles.push_back(buffer[buffer_index - dv])
						_triangles.push_back(buffer[buffer_index])
						_triangles.push_back(buffer[buffer_index - du])
						_triangles.push_back(buffer[buffer_index - du - dv])
				
				# Inner loop iteration
				n += 1
				buffer_index += 1
			
			# Middle loop iteration
			n += 1
			buffer_index += 2
		
		# Outer loop iteration
		n += _dimensions.x
		buffer_number ^= 1
		R.z = -R.z
