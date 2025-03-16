# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyVerticalVesicaSegment3D
extends PuttyShape3D

@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

@export
var weight := 1.0:
	set(value):
		weight = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.VERTICAL_VESICA_SEGMENT

func get_first_arguments() -> Vector4:
	return Vector4(height, weight, 0.0, 0.0)
