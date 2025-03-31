@tool
class_name GLTFDocumentExtensionPuttyShape
extends GLTFDocumentExtension


# TODO: Get a better extension name under a reserved prefix (after everything's functional).
const EXTENSION_NAME: String = "WIP_putty_shape"


# Import process.
func _import_preflight(gltf_state: GLTFState, extensions: PackedStringArray) -> Error:
	if extensions.has(EXTENSION_NAME):
		return OK
	return ERR_SKIP


func _get_supported_extensions() -> PackedStringArray:
	return PackedStringArray([EXTENSION_NAME])


func _parse_node_extensions(gltf_state: GLTFState, gltf_node: GLTFNode, extensions: Dictionary) -> Error:
	if not extensions.has(EXTENSION_NAME):
		return OK
	# NOTE: This function is for reading in the glTF JSON data into in-memory data.
	# This is effectively an in-between state that makes things easier to work with.
	# Use Godot data types here as needed (convert numbers to int, Vector3, AABB, etc)
	# but generally try to keep the data similar to what was in the glTF file.
	# As such, don't return early in one of the cases - we want to read in all of the data.
	# The conversion to Godot nodes will happen in `_generate_scene_node`.
	var putty_ext: Dictionary = extensions[EXTENSION_NAME]
	if putty_ext.has("sampleSpace"):
		var sample_space_arr: Array = putty_ext["sampleSpace"]
		if sample_space_arr.size() != 6:
			printerr("glTF import: Putty mesher sample space is not a valid AABB.")
		else:
			var sample_space_pos := Vector3(sample_space_arr[0], sample_space_arr[1], sample_space_arr[2])
			var sample_space_size := Vector3(sample_space_arr[3], sample_space_arr[4], sample_space_arr[5])
			# Use whatever name you want here, but keep it consistent with exporting.
			gltf_node.set_additional_data(&"PuttyMesherSampleSpace", AABB(sample_space_pos, sample_space_size))
	if putty_ext.has("shape"):
		var shape_index: int = putty_ext["shape"]
		# NOTE: Only keep track of the index, don't grab a reference yet.
		# This allows you to freely alter or swap out the shape in another step like
		# `import_post_parse` and then it's only grabbed as needed when generating the node.
		gltf_node.set_additional_data(&"PuttyGLTFPhysicsShapeIndex", shape_index)
	return OK


func _generate_putty_shape_node(putty_shape: GLTFPhysicsShape) -> Node3D:
	var shape_node: PuttyShape3D
	match putty_shape.shape_type:
		"box":
			# TODO: Read in any other box properties and check if we need to generate
			# `PuttyRoundedBox3D` or something instead of `PuttyBox3D`.
			shape_node = PuttyBox3D.new()
			shape_node.bounds = putty_shape.size
		"sphere":
			shape_node = PuttySphere3D.new()
			shape_node.radius = putty_shape.radius
	return shape_node


func _generate_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_parent: Node) -> Node3D:
	var sample_space = gltf_node.get_additional_data(&"PuttyMesherSampleSpace")
	if sample_space is AABB:
		var putty_mesher := PuttyMesher3D.new()
		putty_mesher.sample_space = sample_space
		return putty_mesher
	var putty_shape_index = gltf_node.get_additional_data(&"PuttyGLTFPhysicsShapeIndex")
	if putty_shape_index is int and putty_shape_index >= 0:
		var state_shapes = gltf_state.get_additional_data(&"GLTFPhysicsShapes")
		if state_shapes is Array and putty_shape_index < state_shapes.size():
			var putty_shape: GLTFPhysicsShape = state_shapes[putty_shape_index]
			if putty_shape != null:
				if not scene_parent is PuttyMesher3D:
					push_warning("glTF import: Warning: The parent of a PuttyShape3D is not a PuttyMesher3D.")
				return _generate_putty_shape_node(putty_shape)
	return null


func _import_post(gltf_state: GLTFState, root: Node) -> Error:
	# This is run at the very end of the glTF import, right before handing
	# control back to the editor's general 3D scene import process.
	# Then after the editor's done, it saves the resulting Godot scene in the `.godot/imported/` folder.
	var putty_meshers = root.find_children("", "PuttyMesher3D")
	for putty_mesher in putty_meshers:
		# TODO: Replace this with a function to force the mesher to update its mesh immediately.
		putty_mesher.submit_request()
	return OK


# Export process.
func _convert_scene_node(gltf_state: GLTFState, gltf_node: GLTFNode, scene_node: Node) -> void:
	if scene_node is PuttyMesher3D:
		# Use whatever name you want here, but keep it consistent with importing.
		gltf_node.set_additional_data(&"PuttyMesherSampleSpace", scene_node.sample_space)
		return
	if scene_node is PuttyShape3D:
		var shape := GLTFPhysicsShape.new()
		if scene_node is PuttyBox3D:
			shape.shape_type = "box"
			shape.size = scene_node.bounds
		elif scene_node is PuttySphere3D:
			shape.shape_type = "sphere"
			shape.radius = scene_node.radius
		else:
			# TODO: You will need to add more shapes above here. For adding more data to
			# the shape to be read later, you can use "set_meta" on the GLTFPhysicsShape.
			# Ex: For rounded box, maybe you do `shape.set_meta("rounding_radius", scene_node.rounding_radius)`
			# in addition to `shape.shape_type = "box"` and `shape.size = scene_node.bounds`.
			# Some glTF classes have `set_additional_data` for effectively the same thing, but it
			# makes it clearer that it's intentional for glTF, since `set_meta` is a global Godot thing.
			# Also I usually use snake_case for meta, but additional data often includes a class name
			# so I usually use PascalCase for that, but it really does not matter at all, any casing works.
			# P.S.: Or, alternatively, you can make a new class that extends `GLTFPhysicsShape`.
			printerr("glTF export: Unrecognized type of putty shape node " + scene_node.name)
			return
		gltf_node.set_additional_data(&"PuttyGLTFPhysicsShape", shape)


func _get_or_create_state_omi_shapes_in_state(gltf_state: GLTFState) -> Array:
	var state_json: Dictionary = gltf_state.get_json()
	var state_extensions: Dictionary
	if state_json.has("extensions"):
		state_extensions = state_json["extensions"]
	else:
		state_json["extensions"] = state_extensions
	var putty_shape_ext: Dictionary
	if state_extensions.has("OMI_physics_shape"):
		putty_shape_ext = state_extensions["OMI_physics_shape"]
	else:
		state_extensions["OMI_physics_shape"] = putty_shape_ext
		gltf_state.add_used_extension("OMI_physics_shape", false)
	var state_shapes: Array
	if putty_shape_ext.has("shapes"):
		state_shapes = putty_shape_ext["shapes"]
	else:
		putty_shape_ext["shapes"] = state_shapes
	return state_shapes


func _export_node_shape(gltf_state: GLTFState, gltf_shape: GLTFPhysicsShape) -> int:
	var state_shapes: Array = _get_or_create_state_omi_shapes_in_state(gltf_state)
	var size: int = state_shapes.size()
	var shape_dict: Dictionary = gltf_shape.to_dictionary()
	# TODO: If you set extra properties with `set_meta`, use `get_meta` here and put them in `shape_dict`.
	# If you want to contain this behavior in another class, another option is to make one and use `set_meta`
	# to store a reference to it in the shape, then you can use that class's properties and functions.
	for i in range(size):
		var other: Dictionary = state_shapes[i]
		if other == shape_dict:
			# De-duplication: If we already have an identical shape,
			# set the shape index to the existing one and return.
			return i
	# If we don't have an identical shape, add it to the array.
	state_shapes.append(shape_dict)
	return size


func _export_preserialize(gltf_state: GLTFState) -> Error:
	# Note: Need to do `_export_node_shape` before exporting animations, so `export_node` is too late.
	# This gives us the ability to support shape animations later if we want.
	var state_gltf_nodes: Array[GLTFNode] = gltf_state.get_nodes()
	for gltf_node in state_gltf_nodes:
		var shape = gltf_node.get_additional_data(&"PuttyGLTFPhysicsShape")
		if shape != null:
			var shape_index: int = _export_node_shape(gltf_state, shape)
			gltf_node.set_additional_data(&"PuttyGLTFPhysicsShapeIndex", shape_index)
	return OK


func _export_node(gltf_state: GLTFState, gltf_node: GLTFNode, json: Dictionary, node: Node) -> Error:
	var sample_space = gltf_node.get_additional_data(&"PuttyMesherSampleSpace")
	if sample_space is AABB:
		var node_ext: Dictionary = json.get_or_add("extensions", {})
		var node_putty: Dictionary = node_ext.get_or_add(EXTENSION_NAME, {})
		# NOTE: glTF identifiers are usually one word, but use camelCase by convention.
		# You must export a JSON-compatible type, so an array of 6 numbers for an AABB.
		# However, it may be more glTF-like to use two Vector3 values (array of 3 numbers)
		# instead of an AABB, but I'm not sure it matters... I guess do whatever you want.
		# I'm gonna do an array of 6 numbers here purely because I don't want to think about it.
		# Also you might want to have a sub-object like `"mesher": { "sampleSpace": [...] }` depending on complexity.
		node_putty["sampleSpace"] = [sample_space.position.x, sample_space.position.y, sample_space.position.z, sample_space.size.x, sample_space.size.y, sample_space.size.z]
	var shape_index = gltf_node.get_additional_data(&"PuttyGLTFPhysicsShapeIndex")
	if shape_index is int:
		var node_ext: Dictionary = json.get_or_add("extensions", {})
		var node_putty: Dictionary = node_ext.get_or_add(EXTENSION_NAME, {})
		node_putty["shape"] = shape_index
		gltf_state.add_used_extension(EXTENSION_NAME, false)
	return OK
