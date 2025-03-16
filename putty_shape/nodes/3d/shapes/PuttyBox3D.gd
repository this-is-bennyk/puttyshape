# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://putty_shape/icons/putty_box_3D.svg")
class_name PuttyBox3D
extends PuttyShape3D

@export_custom(PROPERTY_HINT_LINK, "")
var bounds := Vector3.ONE:
	set(value):
		bounds = value.abs()
		_update_parent()

func get_shape_type() -> int:
	return Shapes.BOX

func get_first_arguments() -> Vector4:
	return Vector4(bounds.x, bounds.y, bounds.z, 0.0)
