# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyRhombus3D
extends PuttyShape3D

@export
var horizontal_length := 1.0:
	set(value):
		horizontal_length = absf(value)
		_update_parent()

@export
var vertical_length := 1.0:
	set(value):
		vertical_length = absf(value)
		_update_parent()

@export
var height := 0.2:
	set(value):
		height = absf(value)
		_update_parent()

@export
var radius := 0.0:
	set(value):
		radius = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.RHOMBUS

func get_first_arguments() -> Vector4:
	return Vector4(horizontal_length, vertical_length, height, radius)
