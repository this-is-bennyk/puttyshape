# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://putty_shape/icons/putty_capsule_3D.svg")
class_name PuttyVerticalCapsule3D
extends PuttyShape3D

@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.VERTICAL_CAPSULE

func get_first_arguments() -> Vector4:
	return Vector4(height, radius, 0.0, 0.0)
