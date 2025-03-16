@tool
class_name PuttyBend3D
extends PuttyModifier3D

@export
var bend_amount := 0.0

func modify_position(position: Vector3) -> Vector3:
	var bending := Vector2(position.x, position.y).rotated(bend_amount * position.x)
	return Vector3(bending.x, bending.y, position.z)
