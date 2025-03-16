# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
class_name PuttyEllipsoidBound3D
extends PuttyShape3D

@export_custom(PROPERTY_HINT_LINK, "")
var radii := Vector3(1.0, 0.5, 2.0):
	set(value):
		radii = value.abs()
		_update_parent()

func get_shape_type() -> int:
	return Shapes.ELLIPSOID_BOUND

func get_first_arguments() -> Vector4:
	return Vector4(radii.x, radii.y, radii.z, 0.0)
