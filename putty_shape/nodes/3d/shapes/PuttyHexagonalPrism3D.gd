# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyHexagonalPrism3D
extends PuttyShape3D

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

@export
var length := 1.0:
	set(value):
		length = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.HEXAGONAL_PRISM

func get_first_arguments() -> Vector4:
	return Vector4(radius, length, 0.0, 0.0)
