# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyVerticalRoundCone3D
extends PuttyShape3D

@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

@export
var bottom_radius := 1.0:
	set(value):
		bottom_radius = absf(value)
		_update_parent()

@export
var top_radius := 0.5:
	set(value):
		top_radius = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.VERTICAL_ROUND_CONE

func get_first_arguments() -> Vector4:
	return Vector4(height, bottom_radius, top_radius, 0.0)
