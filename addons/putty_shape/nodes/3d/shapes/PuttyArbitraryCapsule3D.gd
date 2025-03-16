# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://putty_shape/icons/putty_arbitrary_capsule_3D.svg")
class_name PuttyArbitraryCapsule3D
extends PuttyShape3D

@export
var start := -Vector3.UP:
	set(value):
		start = value
		_update_parent()

@export
var end := Vector3.UP:
	set(value):
		end = value
		_update_parent()

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.ARBITRARY_CAPSULE

func get_first_arguments() -> Vector4:
	return Vector4(start.x, start.y, start.z, end.x)

func get_second_arguments() -> Vector4:
	return Vector4(end.y, end.z, radius, 0.0)
