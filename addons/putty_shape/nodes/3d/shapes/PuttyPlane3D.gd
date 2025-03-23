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

# Shape taken from Inigo Quilez's article on 3D SDFs
# https://iquilezles.org/articles/distfunctions/
# Licensed under the MIT License.

@tool
@icon("res://addons/putty_shape/icons/putty_plane_3D.svg")
class_name PuttyPlane3D
extends PuttyShape3D

## Creates a plane that stretches forever.
##
## [b]NOTE[/b]: Infinite shapes, in 3D mesh generation, are best used to create subtractions
## or intersections with shapes, as opposed to unions (they will always get cut off by the bounding box).
## 
## @tutorial(From Inigo Quilez's SDF functions): https://iquilezles.org/articles/distfunctions/

## The vector representing the direction of the plane.
## Normalized when passed to the parent [PuttyMesher3D].
@export
var normal := Vector3.UP:
	set(value):
		if value.is_zero_approx():
			return
		normal = value
		_update_parent()

## The offset from the origin in the direction of the [member normal].
@export
var height := 0.5:
	set(value):
		height = absf(value)
		_update_parent()

## See [method PuttyShape3D.get_shape_type].
func get_shape_type() -> int:
	return Shapes.PLANE

## See [method PuttyShape3D.get_first_arguments].
func get_first_arguments() -> Vector4:
	var normalized := normal.normalized()
	return Vector4(normalized.x, normalized.y, normalized.z, height)
