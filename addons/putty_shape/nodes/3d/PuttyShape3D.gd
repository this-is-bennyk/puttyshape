# MIT License
# 
# Copyright (c) 2025 Ben Kurtin
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
@icon("res://addons/putty_shape/icons/putty_shape_3D.svg")
class_name PuttyShape3D
extends Node3D

## Base class for providing information to a parent [PuttyMesher3D] or [PuttyRenderer3D] about what to draw.
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

## How to combine the [PuttyShape3D] into its parent [PuttyMesher3D] or [PuttyRenderer3D].
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
	## Same as union, but smoothly transitions to any other shape it intersects with instead of leaving a hard edge.[br]
	## Use [member combination_first_radius] to specify the smoothing radius.
	SMOOTH_UNION,
	## Same as subtraction, but smoothly transitions to any other shape it intersects with instead of leaving a hard edge.[br]
	## Use [member combination_first_radius] to specify the smoothing radius.
	SMOOTH_SUBTRACTION,
	## Same as intersection, but smoothly transitions to any other shape it intersects with instead of leaving a hard edge.[br]
	## Use [member combination_first_radius] to specify the smoothing radius.
	SMOOTH_INTERSECTION,
	## Same as union, but transitions to any other shape with a 45-degree chamfered edge.[br]
	## Use [member combination_first_radius] to specify the chamfer radius.
	CHAMFER_UNION,
	## Same as subtraction, but transitions to any other shape with a 45-degree chamfered edge.[br]
	## Use [member combination_first_radius] to specify the chamfer radius.
	CHAMFER_SUBTRACTION,
	## Same as intersection, transitions to any other shape with a 45-degree chamfered edge.[br]
	## Use [member combination_first_radius] to specify the chamfer radius.
	CHAMFER_INTERSECTION,
	## Same as union, but transitions to any other shape with a quarter-circle.[br]
	## Use [member combination_first_radius] to specify the rounding radius.
	ROUND_UNION,
	## Same as subtraction, but transitions to any other shape with a quarter-circle.[br]
	## Use [member combination_first_radius] to specify the rounding radius.
	ROUND_SUBTRACTION,
	## Same as intersection, but transitions to any other shape with a quarter-circle.[br]
	## Use [member combination_first_radius] to specify the rounding radius.
	ROUND_INTERSECTION,
	## Same as round union, but plays better with acute angles.[br]
	## Use [member combination_first_radius] to specify the rounding radius.
	SOFT_UNION,
	## Removes all shapes this shape intersects with, including itself, and leaves a pipe
	## around the intersections.[br]
	## Use [member combination_first_radius] to specify the pipe's radius.
	PIPE,
	## Leaves a V-shaped intersection in any other shape this shape intersects with.[br]
	## Use [member combination_first_radius] to specify the engraving radius.
	ENGRAVE,
	## Leaves a groove cutout in any other shape this shape intersects with.[br]
	## Use [member combination_first_radius] to specify the groove radius.[br]
	## Use [member combination_second_radius] to specify the groove depth.
	GROOVE,
	## Adds a protrusion in any other shape this shape intersects with.[br]
	## Use [member combination_first_radius] to specify the tongue radius.[br]
	## Use [member combination_second_radius] to specify the tongue depth.
	TONGUE,
	## Same as union, but transitions to any other shape with columns at a 45-degree angle.[br]
	## Use [member combination_first_radius] to specify the column's radius.[br]
	## Use [member combination_steps] to specify the number of columns.
	COLUMNS_UNION,
	## Same as subtraction, but transitions to any other shape with columns at a 45-degree angle.[br]
	## Use [member combination_first_radius] to specify the column's radius.[br]
	## Use [member combination_steps] to specify the number of columns.
	COLUMNS_SUBTRACTION,
	## Same as intersection, but transitions to any other shape with columns at a 45-degree angle.[br]
	## Use [member combination_first_radius] to specify the column's radius.[br]
	## Use [member combination_steps] to specify the number of columns.
	COLUMNS_INTERSECTION,
	## Same as union, but transitions to any other shape with stairs at a 45-degree angle.[br]
	## Use [member combination_first_radius] to specify the stair's size.[br]
	## Use [member combination_steps] to specify the number of stairs.
	STAIRS_UNION,
	## Same as subtraction, but transitions to any other shape with stairs at a 45-degree angle.[br]
	## Use [member combination_first_radius] to specify the stair's size.[br]
	## Use [member combination_steps] to specify the number of stairs.
	STAIRS_SUBTRACTION,
	## Same as intersection, but transitions to any other shape with stairs at a 45-degree angle.[br]
	## Use [member combination_first_radius] to specify the stair's size.[br]
	## Use [member combination_steps] to specify the number of stairs.
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

## Sends a request to the parent [PuttyMesher3D] or [PuttyRenderer3D] to update the mesh.
@export_tool_button("Update")
var update_shape := _update_parent

## Tells the parent [PuttyMesher3D] or [PuttyRenderer3D] how to generate this shape.
#@export
#var generation := GenerationType.DEFAULT

## Tells the parent [PuttyMesher3D] or [PuttyRenderer3D] how to modify this shape.
## An empty stack will default to leaving the shape at the local origin, orientation,
## and scale of this node without modifications.
@export
var modifiers: Array[PuttyModifier3D] = []:
	set(value):
		modifiers = value
		_update_parent()

@export_group("Combination", "combination_")

## Tells the parent [PuttyMesher3D] or [PuttyRenderer3D] how to add this shape into the scene.
@export
var combination_type := CombinationType.UNION:
	set(value):
		combination_type = value
		_update_parent()

## One of the radii parameters for certain combination types.
@export
var combination_first_radius := 0.0:
	set(value):
		combination_first_radius = absf(value)
		_update_parent()

## One of the radii parameters for certain combination types.
@export
var combination_second_radius := 0.0:
	set(value):
		combination_second_radius = absf(value)
		_update_parent()

## The number of steps for certain combination types.
@export
var combination_steps := 1:
	set(value):
		combination_steps = maxi(absi(value), 1)
		_update_parent()

func _ready() -> void:
	set_notify_local_transform(true)

func _get_configuration_warnings() -> PackedStringArray:
	var result := PackedStringArray()
	
	var parent_isnt_container3D := get_parent() is not PuttyMesher3D
	var parent_isnt_container_psuedo_3D := get_parent() is not PuttyRenderer3D
	
	if parent_isnt_container3D and parent_isnt_container_psuedo_3D:
		result.push_back("Parent must be an PuttyMesher3D or a PuttyRenderer3D. This node will do nothing.")
	
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
	
	if get_parent() is PuttyMesher3D:
		(get_parent() as PuttyMesher3D).submit_request()
	elif get_parent() is PuttyRenderer3D:
		(get_parent() as PuttyRenderer3D).refresh_shape(self)
	else:
		printerr("Parent must be an PuttyMesher3D or a PuttyRenderer3D. This node will do nothing.")
