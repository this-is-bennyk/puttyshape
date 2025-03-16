# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyInfiniteCylinder3D
extends PuttyShape3D

@export
var position_offset := Vector2.ZERO:
	set(value):
		position_offset = value.abs()
		_update_parent()

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.INFINITE_CYLINDER

func get_first_arguments() -> Vector4:
	return Vector4(position_offset.x, position_offset.y, radius, 0.0)
