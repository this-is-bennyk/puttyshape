# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyBoxFrame3D
extends PuttyShape3D

@export_custom(PROPERTY_HINT_LINK, "")
var bounds := Vector3.ONE:
	set(value):
		bounds = value.abs()
		_update_parent()

@export
var edge_width := 0.1:
	set(value):
		edge_width = absf(value)
		_update_parent()

func get_shape_type() -> int:
	return Shapes.BOX_FRAME

func get_first_arguments() -> Vector4:
	return Vector4(bounds.x, bounds.y, bounds.z, edge_width)
