# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyArbitraryVesicaSegment3D
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
var weight := 1.0:
	set(value):
		weight = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.ARBITRARY_VESICA_SEGMENT

func get_first_arguments() -> Vector4:
	return Vector4(start.x, start.y, start.z, end.x)

func get_second_arguments() -> Vector4:
	return Vector4(end.y, end.z, weight, 0.0)
