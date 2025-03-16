# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyInfiniteCone3D
extends PuttyShape3D

@export_range(-360.0, 360.0, 0.5, "degrees")
var angle_degrees := 45.0:
	set(value):
		angle_degrees = value
		_update_parent()

func get_shape_type() -> int:
	return Shapes.INFINITE_CONE

func get_first_arguments() -> Vector4:
	return Vector4(deg_to_rad(angle_degrees), 0.0, 0.0, 0.0)
