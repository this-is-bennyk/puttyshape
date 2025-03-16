# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://putty_shape/icons/putty_sphere_3D.svg")
class_name PuttySphere3D
extends PuttyShape3D

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

func _get_sdf_sample(pos: Vector3) -> float:
	return pos.length() - radius

func get_shape_type() -> int:
	return Shapes.SPHERE

func get_first_arguments() -> Vector4:
	return Vector4(radius, 0.0, 0.0, 0.0)
