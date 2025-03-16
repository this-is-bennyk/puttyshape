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
class_name PuttyModifier3D
extends Resource

## Specifies how to modify an [PuttyShape3D].
## 
## You can apply as many modifiers as you want (within reason for the GPU, of course).

### Which modification to apply to the [PuttyShape3D].
#enum ModificationType
#{
	## Warps the mesh with an equation.
	##DISPLACEMENT,
	### Twists the mesh like a corkscrew.
	#TWIST,
	### Bends the mesh like a piece of paper.
	#BEND,
	### Flips the shape on an axis, plane, or dimension.
	#SWIZZLE,
	### Symmetrically mirrors the shape on an axis, plane, or dimension.
	#SYMMETRICAL_SWIZZLE,
	### Repeats the shape forever.
	#INFINITE_DOMAIN_REPETITION,
	### Repeats the shape within a certain size limit.
	#FINITE_DOMAIN_REPETITION,
	### Expands the shape in the cardinal directions.
	#ELONGATION,
#}
#
### Which axis or plane to swizzle. Used with [constant ModificationType.SWIZZLE] and [constant ModificationType.SYMMETRICAL_SWIZZLE].
#enum SwizzleType
#{
	### X-axis.
	#X,
	### Y-axis.
	#Y,
	### Z-axis.
	#Z,
#
	### XY-plane.
	#XY,
	### YX-plane (XY-plane where the X- and Y-axes are swapped).
	#YX,
	### XZ-plane.
	#XZ,
	### ZX-plane (XZ-plane where the Z- and X-axes are swapped).
	#ZX,
	### YZ-plane.
	#YZ,
	### ZY-plane (YZ-plane where the Y- and Z-axes are swapped).
	#ZY,
#
	### XYZ dimension.
	#XYZ,
	### XZY dimension (XYZ dimension where the Y- and Z-axes are swapped).
	#XZY,
	### YXZ dimension (XYZ dimension where the X- and Y-axes are swapped).
	#YXZ,
	### YXZ dimension (XYZ dimension where all axes are swapped counterclockwise).
	#YZX,
	### YXZ dimension (XYZ dimension where all axes are swapped clockwise).
	#ZXY,
	### YXZ dimension (XYZ dimension where the X- and Z-axes are swapped).
	#ZYX,
#}
#
### The type of modification to perform.
#@export
#var modification := ModificationType.TWIST
#
#@export_group("Swizzling", "swizzle_")
#
### The type of swizzle to perform. Used with [constant ModificationType.SWIZZLE] and [constant ModificationType.SYMMETRICAL_SWIZZLE].
#@export
#var swizzle := SwizzleType.X
#
#@export_group("Repetition", "repetition_")
#
### How spaced apart the repeated shapes should be.
### Used with [constant ModificationType.INFINITE_DOMAIN_REPETITION] and [constant ModificationType.FINITE_DOMAIN_REPETITION].
#@export_custom(PROPERTY_HINT_LINK, "")
#var repetition_spacing := Vector3():
	#set(value):
		#repetition_spacing = value.abs()
#
### How much space the repeated shapes are allowed to take up before being cut off.
### Used with [constant ModificationType.FINITE_DOMAIN_REPETITION].
#@export_custom(PROPERTY_HINT_LINK, "")
#var repetition_size := Vector3():
	#set(value):
		#repetition_size = value.abs()
#
#@export_group("Elongation", "elongation_")
#
#@export_custom(PROPERTY_HINT_LINK, "")
#var elongation_lengths := Vector3():
	#set(value):
		#repetition_size = value.abs()

func modify_position(position: Vector3) -> Vector3:
	assert(false, "Abstract function!")
	return position
