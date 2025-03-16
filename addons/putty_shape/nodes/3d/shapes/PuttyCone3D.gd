# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyCone3D
extends PuttyShape3D

@export_range(0.0, 90.0, 0.5, "degrees")
var angle_degrees := 45.0:
	set(value):
		angle_degrees = value
		_update_parent()

@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.CONE

func get_first_arguments() -> Vector4:
	return Vector4(deg_to_rad(angle_degrees), height, 0.0, 0.0)
