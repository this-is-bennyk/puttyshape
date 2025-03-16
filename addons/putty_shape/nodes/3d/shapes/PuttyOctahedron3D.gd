# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyOctahedron3D
extends PuttyShape3D

@export
var radius := 1.0:
	set(value):
		radius = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.OCTAHEDRON

func get_first_arguments() -> Vector4:
	return Vector4(radius, 0.0, 0.0, 0.0)
