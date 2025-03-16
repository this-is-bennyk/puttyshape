# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://putty_shape/icons/putty_torus_3D.svg")
class_name PuttyTorus3D
extends PuttyShape3D

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

@export
var thickness := 0.5:
	set(value):
		thickness = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.TORUS

func get_first_arguments() -> Vector4:
	return Vector4(radius, thickness, 0.0, 0.0)
