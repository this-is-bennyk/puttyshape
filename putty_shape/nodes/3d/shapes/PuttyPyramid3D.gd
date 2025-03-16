# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyPyramid3D
extends PuttyShape3D

@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.PYRAMID

func get_first_arguments() -> Vector4:
	return Vector4(height, 0.0, 0.0, 0.0)
