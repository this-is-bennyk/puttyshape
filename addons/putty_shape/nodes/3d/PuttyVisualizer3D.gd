@tool
class_name PuttyVisualizer3D
extends MultiMeshInstance3D

const PUTTY_RENDER_SURFACE_3D := preload("res://addons/putty_shape/datatypes/3d/PuttyRenderSurface3D.obj")
const PUTTY_RAYMARCHER_3D := preload("res://addons/putty_shape/shaders/3d/PuttyRaymarcher3D.gdshader")
const NEAR_OFFSET := 0.01

var _renderer: PuttyRenderer3D = null
var _cameras: Array[Camera3D] = []

func _ready() -> void:
	_renderer = get_parent() as PuttyRenderer3D
	
	var visualizer := MultiMesh.new()
	
	visualizer.transform_format = MultiMesh.TRANSFORM_3D
	visualizer.mesh = PUTTY_RENDER_SURFACE_3D
	visualizer.physics_interpolation_quality = MultiMesh.INTERP_QUALITY_HIGH
	
	multimesh = visualizer
	material_override = _renderer._shader_material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ignore_occlusion_culling = true
	gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	
	_update_cameras()

func _update_cameras() -> void:
	_cameras.clear()
	_cameras.assign(get_tree().get_nodes_in_group(_renderer.camera_tag))
	
	if Engine.is_editor_hint() and _renderer.camera_apply_to_editor:
		for cam_idx: int in 4:
			_cameras.push_back(EditorInterface.get_editor_viewport_3d(cam_idx).get_camera_3d())
	
	if _cameras.size() > 0:
		var render_rotation := Basis(Quaternion.from_euler(Vector3.RIGHT * PI / 2.0))
		var render_transform := Transform3D(render_rotation, Vector3(-1.0, 1.0, -(_cameras[0].near + NEAR_OFFSET)))
	
	multimesh.instance_count = _cameras.size()
	_update_transforms()

func _physics_process(delta: float) -> void:
	_update_transforms()

func _update_transforms() -> void:
	if _cameras.size() <= 0:
		return
	
	var prev_buffer := multimesh.buffer
	
	var render_rotation := Basis(Quaternion.from_euler(Vector3.RIGHT * PI / 2.0))
	
	for camera_idx: int in _cameras.size():
		var camera := _cameras[camera_idx]
		var render_transform := Transform3D(render_rotation, Vector3(-1.0, 1.0, -(camera.near + NEAR_OFFSET)))
		
		multimesh.set_instance_transform(camera_idx, camera.global_transform * render_transform)
	
	multimesh.set_buffer_interpolated(multimesh.buffer, prev_buffer)
