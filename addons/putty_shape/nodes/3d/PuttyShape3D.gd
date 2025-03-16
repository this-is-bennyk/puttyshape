@tool
class_name PuttyShape3D
extends Node3D

## Base class for providing information to a parent [PuttyContainer3D] about what to draw.
## 
## The [PuttyShape3D] is a node that contains information for a particular kind of shape
## to render using a [b]signed distance field[/b] ([b]SDF[/b]) function. It does not
## create the distances itself; its properties are sent to a compute shader to do the
## calculations.

## How to generate the shape to draw.
#enum GenerationType
#{
	### Draws the shape without modification.
	#DEFAULT,
	## Extends the provided [SDFShape2D] by translation.
	##EXTRUSION,
	## Extends the provided [SDFShape2D] by rotation around a central axis.
	##REVOLUTION,
	### Repeats the shape forever.
	#INFINITE_DOMAIN_REPETITION,
	### Repeats the shape forever by mirroring it.
	#INFINITE_MIRRORED_DOMAIN_REPETITION,
	### Repeats the shape within a certain size limit. Less expensive than repeating forever, but produces a different effect.
	#FINITE_DOMAIN_REPETITION,
	### Repeats the shape within a certain size limit by mirroring it. Less expensive than repeating forever, but produces a different effect.
	#FINITE_MIRRORED_DOMAIN_REPETITION,
#}

## How to combine the [PuttyShape3D] into its parent [PuttyContainer3D].
enum CombinationType
{
	## Inserts the shape without modification.
	UNION,
	## Unions the shape, but cuts out anywhere it intersects with another shape.
	XOR,
	## Subtracts this shape from anywhere it intersects with another shape.
	SUBTRACTION,
	## Leaves the cross-section between this shape and any other shape it intersects with.
	INTERSECTION,
	## Same as union, but smoothly transitions to any other shape it intersects with instead of leaving a hard edge.
	SMOOTH_UNION,
	## Same as subtraction, but smoothly transitions to any other shape it intersects with instead of leaving a hard edge. 
	SMOOTH_SUBTRACTION,
	## Same as intersection, but smoothly transitions to any other shape it intersects with instead of leaving a hard edge.
	SMOOTH_INTERSECTION,
	## Same as union, but transitions to any other shape with a 45-degree chamfered edge.
	CHAMFER_UNION,
	## Same as subtraction, but transitions to any other shape with a 45-degree chamfered edge.
	CHAMFER_SUBTRACTION,
	## Same as intersection, transitions to any other shape with a 45-degree chamfered edge.
	CHAMFER_INTERSECTION,
	## Same as union, but transitions to any other shape with a quarter-circle.
	ROUND_UNION,
	## Same as subtraction, but transitions to any other shape with a quarter-circle.
	ROUND_SUBTRACTION,
	## Same as intersection, but transitions to any other shape with a quarter-circle.
	ROUND_INTERSECTION,
	## Same as round union, but more Lipschitz-y at acute angles. (Wth does that mean??)
	SOFT_UNION,
	## Removes all shapes this shape intersects with, including itself, and leaves a pipe
	## around the intersections.
	PIPE,
	## Leaves a V-shaped intersection in any other shape this shape intersects with.
	ENGRAVE,
	## Leaves a groove cutout in any other shape this shape intersects with.
	GROOVE,
	## Adds a protrusion in any other shape this shape intersects with.
	TONGUE,
	## Same as union, but transitions to any other shape with columns at a 45-degree angle.
	COLUMNS_UNION,
	## Same as subtraction, but transitions to any other shape with columns at a 45-degree angle.
	COLUMNS_SUBTRACTION,
	## Same as intersection, but transitions to any other shape with columns at a 45-degree angle.
	COLUMNS_INTERSECTION,
	## Same as union, but transitions to any other shape with stairs at a 45-degree angle.
	STAIRS_UNION,
	## Same as subtraction, but transitions to any other shape with stairs at a 45-degree angle.
	STAIRS_SUBTRACTION,
	## Same as intersection, but transitions to any other shape with stairs at a 45-degree angle.
	STAIRS_INTERSECTION,
}

## [b]Internal use only.[/b] Which shape to draw.
enum Shapes
{
	SPHERE,
	BOX,
	ROUNDED_BOX,
	BOX_FRAME,
	TORUS,
	CAPPED_TORUS,
	LINK,
	INFINITE_CYLINDER,
	CONE,
	INFINITE_CONE,
	PLANE,
	HEXAGONAL_PRISM,
	TRIANGULAR_PRISM,
	VERTICAL_CAPSULE,
	ARBITRARY_CAPSULE,
	VERTICAL_CAPPED_CYLINDER,
	ARBITRARY_CAPPED_CYLINDER,
	ROUNDED_CYLINDER,
	VERTICAL_CAPPED_CONE,
	ARBITRARY_CAPPED_CONE,
	SOLID_ANGLE,
	CUT_SPHERE,
	CUT_HOLLOW_SPHERE,
	VERTICAL_ROUND_CONE,
	ARBITRARY_ROUND_CONE,
	ELLIPSOID_BOUND,
	VERTICAL_VESICA_SEGMENT,
	ARBITRARY_VESICA_SEGMENT,
	RHOMBUS,
	OCTAHEDRON,
	PYRAMID,
}

@export_tool_button("Update")
var update_shape := _update_parent

## Tells the parent [PuttyContainer3D] how to generate this shape.
#@export
#var generation := GenerationType.DEFAULT

## Tells the parent [PuttyContainer3D] how to modify this shape.
## An empty stack will default to leaving the shape at the local origin, orientation,
## and scale of this node without modifications.
@export
var modifiers: Array[PuttyModifier3D] = []:
	set(value):
		modifiers = value
		_update_parent()

@export_group("Combination", "combination_")

## Tells the parent [PuttyContainer3D] how to add this shape into the scene.
@export
var combination_type := CombinationType.UNION:
	set(value):
		combination_type = value
		_update_parent()

@export
var combination_first_radius := 0.0:
	set(value):
		combination_first_radius = absf(value)
		_update_parent()

@export
var combination_second_radius := 0.0:
	set(value):
		combination_second_radius = absf(value)
		_update_parent()

@export
var combination_steps := 1:
	set(value):
		combination_steps = maxi(absi(value), 1)
		_update_parent()

func _ready() -> void:
	set_notify_local_transform(true)

func _get_configuration_warnings() -> PackedStringArray:
	var result := PackedStringArray()
	
	if get_parent() is not PuttyContainer3D:
		result.push_back("Parent must be an PuttyContainer3D. This node will do nothing.")
	
	return result

## Returns the type of shape this is for the compute shader. Overriden by derived classes.
func get_shape_type() -> int:
	assert(false, "Abstract function!")
	return Shapes.SPHERE

## Returns the first set of arguments of this shape flattened to a [Vector4] for the compute shader. Overriden by derived classes.
func get_first_arguments() -> Vector4:
	return Vector4()

## Returns the second set of arguments of this shape flattened to a [Vector4] for the compute shader. Overriden by derived classes.
func get_second_arguments() -> Vector4:
	return Vector4()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_LOCAL_TRANSFORM_CHANGED:
			_update_parent()

func _update_parent() -> void:
	if not is_inside_tree():
		return
	
	if get_parent() is not PuttyContainer3D:
		printerr("Parent must be an PuttyContainer3D. This node will do nothing.")
		return
	
	(get_parent() as PuttyContainer3D).submit_request()
