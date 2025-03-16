@tool
class_name PuttyTwist3D
extends PuttyModifier3D

@export
var twist_amount := 0.0

func modify_position(position: Vector3) -> Vector3:
	var twisting := Vector2(position.x, position.z).rotated(twist_amount * position.y)
	return Vector3(twisting.x, twisting.y, position.y)
