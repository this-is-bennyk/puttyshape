# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyCutHollowSphere3D
extends PuttyShape3D

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

@export
var cut_depth := 0.2:
	set(value):
		cut_depth = value
		_update_parent()

@export
var thickness := 0.1:
	set(value):
		thickness = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.CUT_HOLLOW_SPHERE

func get_first_arguments() -> Vector4:
	return Vector4(radius, cut_depth, thickness, 0.0)
