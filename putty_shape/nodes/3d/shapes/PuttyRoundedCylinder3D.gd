# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyRoundedCylinder3D
extends PuttyShape3D

@export
var cylinder_radius := 1.0:
	set(value):
		cylinder_radius = absf(value)
		_update_parent()

@export
var rounding_radius := 0.0:
	set(value):
		rounding_radius = absf(value)
		_update_parent()

@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.ROUNDED_CYLINDER

func get_first_arguments() -> Vector4:
	return Vector4(cylinder_radius, rounding_radius, height, 0.0)
