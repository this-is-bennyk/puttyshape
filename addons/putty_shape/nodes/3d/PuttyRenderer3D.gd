@tool
@icon("res://addons/putty_shape/icons/putty_renderer_3D.svg")
class_name PuttyRenderer3D
extends Node3D

## Renders a 3D scene out of [PuttyShape3D]s and their properties.
## 
## The [PuttyRenderer3D] is a specialized 3D node that renders
## children [PuttyShape3D]s by using their corresponding [b]signed distance
## field[/b] ([b]SDF[/b]) functions to determine which points, which are found
## by performing the [b]raymarching[/b] algorithm in a shader to determine what
## color a pixel should draw.[br][br]
## [b][u]NOTE[/u][/b]: Unlike [PuttyMesher3D], [PuttyRenderer3D] does
## [b]not[/b] render the shapes to a usable 3D mesh. You cannot save the shapes
## you create directly to disk as a 3D model. This also means the [PuttyRenderer3D]
## does not interact properly with other 3D graphics nodes such as [Light3D]s and
## [GeometryInstance3D]s.

const PUTTY_RAYMARCHER_3D := preload("res://addons/putty_shape/shaders/3d/PuttyRaymarcher3D.gdshader")

const MAX_IMAGE_SIZE_POW2 := 14
const NUM_SHAPE_DATA_PARAMS := 9
const SIZEOF_VECTOR4 := 16

@export_tool_button("Update Cameras", "Camera3D")
var camera_update := update_cameras

@export_group("Visualizer", "visualizer_")

@export_range(1, 1000)
var visualizer_max_steps := 150:
	set(value):
		visualizer_max_steps = value
		
		if is_instance_valid(_shader_material):
			_shader_material.set_shader_parameter(&"max_steps", value)

@export_range(0.0, 1e12, 0.1)
var visualizer_min_distance := 0.0:
	set(value):
		visualizer_min_distance = clampf(value, 0.0, visualizer_max_distance)
		
		if is_instance_valid(_shader_material):
			_shader_material.set_shader_parameter(&"min_distance", value)

@export_range(1.0, 1e12, 0.1)
var visualizer_max_distance := 256.0:
	set(value):
		visualizer_max_distance = clampf(value, visualizer_min_distance, 1e12)
		
		if is_instance_valid(_shader_material):
			_shader_material.set_shader_parameter(&"max_distance", value)

@export_range(0.01, 1.0, 0.01)
var visualizer_surface_distance := 0.01:
	set(value):
		visualizer_surface_distance = value
		
		if is_instance_valid(_shader_material):
			_shader_material.set_shader_parameter(&"surface_distance", value)

@export_group("Camera", "camera_")

@export
var camera_tag := &"PuttyRenderer3DTarget"

@export
var camera_apply_to_editor := true

var _visualizer: PuttyVisualizer3D = null
var _shader_material := ShaderMaterial.new()

var _shapes: Array[PuttyShape3D] = []
var _shape_data := PackedVector4Array()
var _shape_data_img := Image.new()
var _shape_data_texture: ImageTexture = null
var _shape_data_img_size := 0

func update_cameras() -> void:
	if is_instance_valid(_visualizer):
		_visualizer._update_cameras()

func _ready() -> void:
	_shader_material.shader = PUTTY_RAYMARCHER_3D
	
	_create_visualizer()
	
	if Engine.is_editor_hint():
		tree_entered.connect(_create_visualizer)
	
	set_notify_transform(true)
	child_order_changed.connect(_refresh_scene)
	
	_refresh_scene()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			for shape: PuttyShape3D in _shapes:
				_retrieve_shape_data(shape)
			
			_update_scene()

func _create_visualizer() -> void:
	_visualizer = PuttyVisualizer3D.new()
	add_child(_visualizer, false, Node.INTERNAL_MODE_FRONT)
	_visualizer.top_level = true

func _refresh_scene() -> void:
	_shapes.clear()
	
	for child: Node in get_children():
		if child is not PuttyShape3D:
			continue
		
		_shapes.push_back(child as PuttyShape3D)
	
	_shape_data.clear()
	
	for shape: PuttyShape3D in _shapes:
		var inv_transform := shape.global_transform.affine_inverse()
		
		_shape_data.push_back(Vector4(float(shape.get_shape_type()), 0.0, 0.0, 0.0))
		_shape_data.push_back(Vector4(inv_transform.basis.x.x, inv_transform.basis.x.y, inv_transform.basis.x.z, 0.0))
		_shape_data.push_back(Vector4(inv_transform.basis.y.x, inv_transform.basis.y.y, inv_transform.basis.y.z, 0.0))
		_shape_data.push_back(Vector4(inv_transform.basis.z.x, inv_transform.basis.z.y, inv_transform.basis.z.z, 0.0))
		# REMARK: The end not being a number or 1 seems wrong, but it's working atm
		_shape_data.push_back(Vector4(inv_transform.origin.x, inv_transform.origin.y, inv_transform.origin.z, 0.0))
		_shape_data.push_back(shape.get_first_arguments())
		_shape_data.push_back(shape.get_second_arguments())
		_shape_data.push_back(Vector4(shape.global_transform.basis.get_scale().x, shape.global_transform.basis.get_scale().y, shape.global_transform.basis.get_scale().z, 0.0))
		_shape_data.push_back(Vector4(float(int(shape.combination_type)), shape.combination_first_radius, shape.combination_second_radius, float(shape.combination_steps)))
	
	_update_scene()

func refresh_shape(shape: PuttyShape3D) -> void:
	_retrieve_shape_data(shape)
	_update_scene()

func _retrieve_shape_data(shape: PuttyShape3D) -> void:
	if shape.get_parent() != self:
		return
	
	var child_index := shape.get_index()
	var inv_transform := shape.global_transform.affine_inverse()
	
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 0] = Vector4(float(shape.get_shape_type()), 0.0, 0.0, 0.0)
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 1] = Vector4(inv_transform.basis.x.x, inv_transform.basis.x.y, inv_transform.basis.x.z, 0.0)
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 2] = Vector4(inv_transform.basis.y.x, inv_transform.basis.y.y, inv_transform.basis.y.z, 0.0)
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 3] = Vector4(inv_transform.basis.z.x, inv_transform.basis.z.y, inv_transform.basis.z.z, 0.0)
	# REMARK: The end not being a number or 1 seems wrong, but it's working atm
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 4] = Vector4(inv_transform.origin.x, inv_transform.origin.y, inv_transform.origin.z, 0.0)
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 5] = shape.get_first_arguments()
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 6] = shape.get_second_arguments()
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 7] = Vector4(shape.global_transform.basis.get_scale().x, shape.global_transform.basis.get_scale().y, shape.global_transform.basis.get_scale().z, 0.0)
	_shape_data[child_index * NUM_SHAPE_DATA_PARAMS + 8] = Vector4(float(int(shape.combination_type)), shape.combination_first_radius, shape.combination_second_radius, float(shape.combination_steps))

func _update_scene() -> void:
	if _shapes.size() <= 0:
		return
	
	var prev_size := _shape_data_img_size
	
	_shape_data_img_size = _next_highest_power_of_2_from(ceili(sqrt(_shape_data.size())))
	
	var shape_data_bytes := _shape_data.to_byte_array()
	shape_data_bytes.resize(_shape_data_img_size * _shape_data_img_size * SIZEOF_VECTOR4)
	
	_shape_data_img.set_data(_shape_data_img_size, _shape_data_img_size, false, Image.FORMAT_RGBAF, shape_data_bytes)
	
	if not _shape_data_texture:
		_shape_data_texture = ImageTexture.create_from_image(_shape_data_img)
	elif _shape_data_img_size != prev_size:
		_shape_data_texture.set_image(_shape_data_img)
	else:
		_shape_data_texture.update(_shape_data_img)
	
	_shader_material.set_shader_parameter(&"num_shapes", _shapes.size())
	_shader_material.set_shader_parameter(&"shape_data", _shape_data_texture)

func _next_highest_power_of_2_from(size: int) -> int:
	var num_shifts := 0
	
	size = absi(size)
	
	for i: int in MAX_IMAGE_SIZE_POW2:
		if size & 1 == 1:
			num_shifts = i
		size >>= 1
	
	return 1 << mini(MAX_IMAGE_SIZE_POW2, num_shifts + 1)
