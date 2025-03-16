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
@icon("res://addons/putty_shape/icons/putty_cone_3D.svg")
class_name PuttyCone3D
extends PuttyShape3D

## Creates a pointed cone.
## 
## @tutorial(From Inigo Quilez's SDF functions): https://iquilezles.org/articles/distfunctions/

## The angle of the tip of the cone.
@export_range(0.0, 90.0, 0.5, "degrees")
var angle_degrees := 45.0:
	set(value):
		angle_degrees = value
		_update_parent()

## The height of the cone.
@export
var height := 1.0:
	set(value):
		height = absf(value)
		_update_parent()

## See [method PuttyShape3D.get_shape_type].
func get_shape_type() -> int:
	return Shapes.CONE

## See [method PuttyShape3D.get_first_arguments].
func get_first_arguments() -> Vector4:
	return Vector4(deg_to_rad(angle_degrees), height, 0.0, 0.0)
