# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://putty_shape/icons/putty_plane_3D.svg")
class_name PuttyPlane3D
extends PuttyShape3D

@export
var normal := Vector3.UP:
	set(value):
		if value.is_zero_approx():
			return
		normal = value
		_update_parent()

@export
var height := 0.5:
	set(value):
		height = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.PLANE

func get_first_arguments() -> Vector4:
	var normalized := normal.normalized()
	return Vector4(normalized.x, normalized.y, normalized.z, height)
