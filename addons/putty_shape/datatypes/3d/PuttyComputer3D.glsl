// MIT License
// 
// Copyright (c) 2025 Ben Kurtin
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

// -------------------------------------------------------------------
// Data
// -------------------------------------------------------------------

layout(set = 0, binding = 0, std430) restrict buffer StaticParams
{
    vec3 sample_space_position;
    vec3 sample_space_size;
    vec3 dimensions;
    int num_shapes;
    // int num_points_returned;
    int surface_nets_buffer_size;
}
static_params;

layout(set = 0, binding = 1, std430) restrict buffer Transforms
{
    mat4 matrices[];
}
transforms;

layout(set = 0, binding = 2, std430) restrict buffer ShapeTypes
{
    int types[];
}
shape_types;

layout(set = 0, binding = 3, std430) restrict buffer ShapeParams
{
    vec4 params[];
}
shape_params;

layout(set = 0, binding = 4, std430) restrict buffer Combinations
{
    vec4 types_and_params[];
}
combinations;

layout(set = 0, binding = 5, std430) restrict buffer SurfaceNetsBuffer
{
    int buf[];
}
surface_nets_buffer;

layout(set = 0, binding = 6, std430) restrict buffer Vertices
{
    vec3 points[];
}
vertices;

// layout(set = 0, binding = 7, std430) restrict buffer SamplePositions
// {
//     vec3 points[];
// }
// sample_positions;

layout(set = 0, binding = 7, std430) restrict buffer Triangles
{
    int indices[];
}
triangles;

const float INFINITY = 3.402823466e38;

// -------------------------------------------------------------------
// Shapes
// -------------------------------------------------------------------

const int SDF3D_SHAPE_SPHERE = 0;
const int SDF3D_SHAPE_BOX = SDF3D_SHAPE_SPHERE + 1;
const int SDF3D_SHAPE_ROUNDED_BOX = SDF3D_SHAPE_BOX + 1;
const int SDF3D_SHAPE_BOX_FRAME = SDF3D_SHAPE_ROUNDED_BOX + 1;
const int SDF3D_SHAPE_TORUS = SDF3D_SHAPE_BOX_FRAME + 1;
const int SDF3D_SHAPE_CAPPED_TORUS = SDF3D_SHAPE_TORUS + 1;
const int SDF3D_SHAPE_LINK = SDF3D_SHAPE_CAPPED_TORUS + 1;
const int SDF3D_SHAPE_INFINITE_CYLINDER = SDF3D_SHAPE_LINK + 1;
const int SDF3D_SHAPE_CONE = SDF3D_SHAPE_INFINITE_CYLINDER + 1;
const int SDF3D_SHAPE_INFINITE_CONE = SDF3D_SHAPE_CONE + 1;
const int SDF3D_SHAPE_PLANE = SDF3D_SHAPE_INFINITE_CONE + 1;
const int SDF3D_SHAPE_HEXAGONAL_PRISM = SDF3D_SHAPE_PLANE + 1;
const int SDF3D_SHAPE_TRIANGULAR_PRISM = SDF3D_SHAPE_HEXAGONAL_PRISM + 1;
const int SDF3D_SHAPE_VERTICAL_CAPSULE = SDF3D_SHAPE_TRIANGULAR_PRISM + 1;
const int SDF3D_SHAPE_ARBITRARY_CAPSULE = SDF3D_SHAPE_VERTICAL_CAPSULE + 1;
const int SDF3D_SHAPE_VERTICAL_CAPPED_CYLINDER = SDF3D_SHAPE_ARBITRARY_CAPSULE + 1;
const int SDF3D_SHAPE_ARBITRARY_CAPPED_CYLINDER = SDF3D_SHAPE_VERTICAL_CAPPED_CYLINDER + 1;
const int SDF3D_SHAPE_ROUNDED_CYLINDER = SDF3D_SHAPE_ARBITRARY_CAPPED_CYLINDER + 1;
const int SDF3D_SHAPE_VERTICAL_CAPPED_CONE = SDF3D_SHAPE_ROUNDED_CYLINDER + 1;
const int SDF3D_SHAPE_ARBITRARY_CAPPED_CONE = SDF3D_SHAPE_VERTICAL_CAPPED_CONE + 1;
const int SDF3D_SHAPE_SOLID_ANGLE = SDF3D_SHAPE_ARBITRARY_CAPPED_CONE + 1;
const int SDF3D_SHAPE_CUT_SPHERE = SDF3D_SHAPE_SOLID_ANGLE + 1;
const int SDF3D_SHAPE_CUT_HOLLOW_SPHERE = SDF3D_SHAPE_CUT_SPHERE + 1;
const int SDF3D_SHAPE_VERTICAL_ROUND_CONE = SDF3D_SHAPE_CUT_HOLLOW_SPHERE + 1;
const int SDF3D_SHAPE_ARBITRARY_ROUND_CONE = SDF3D_SHAPE_VERTICAL_ROUND_CONE + 1;
const int SDF3D_SHAPE_ELLIPSOID_BOUND = SDF3D_SHAPE_ARBITRARY_ROUND_CONE + 1;
const int SDF3D_SHAPE_VERTICAL_VESICA_SEGMENT = SDF3D_SHAPE_ELLIPSOID_BOUND + 1;
const int SDF3D_SHAPE_ARBITRARY_VESICA_SEGMENT = SDF3D_SHAPE_VERTICAL_VESICA_SEGMENT + 1;
const int SDF3D_SHAPE_RHOMBUS = SDF3D_SHAPE_ARBITRARY_VESICA_SEGMENT + 1;
const int SDF3D_SHAPE_OCTAHEDRON = SDF3D_SHAPE_RHOMBUS + 1;
const int SDF3D_SHAPE_PYRAMID = SDF3D_SHAPE_OCTAHEDRON + 1;

// The following shapes are taken from Inigo Quilez's article on 3D SDFs
// https://iquilezles.org/articles/distfunctions/
// Licensed under the MIT License.

float sdf3D_sphere(vec3 raycast_position, float radius)
{
	return length(raycast_position) - radius;
}

float sdf3D_box(vec3 raycast_position, vec3 bounds)
{
	vec3 q = abs(raycast_position) - bounds;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdf3D_rounded_box(vec3 raycast_position, vec3 bounds, float rounding_radius)
{
	vec3 q = abs(raycast_position) - bounds + rounding_radius;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - rounding_radius;
}

float sdf3D_box_frame(vec3 raycast_position, vec3 bounds, float edge_width)
{
	raycast_position = abs(raycast_position) - bounds;
	vec3 q = abs(raycast_position + edge_width) - edge_width;
	return min(min(
		length(max(vec3(raycast_position.x, q.y, q.z),0.0)) + min(max(raycast_position.x, max(q.y, q.z)), 0.0),
		length(max(vec3(q.x, raycast_position.y, q.z),0.0)) + min(max(q.x, max(raycast_position.y, q.z)), 0.0)),
		length(max(vec3(q.x, q.y, raycast_position.z),0.0)) + min(max(q.x, max(q.y, raycast_position.z)), 0.0));
}

float sdf3D_torus(vec3 raycast_position, float radius, float thickness)
{
  vec2 q = vec2(length(raycast_position.xz) - radius, raycast_position.y);
  return length(q) - thickness;
}

float sdf3D_capped_torus(vec3 raycast_position, float angle, float radius, float thickness)
{
	vec2 sin_cosine = vec2(sin(angle), cos(angle));
	raycast_position.x = abs(raycast_position.x);
	float k = (sin_cosine.y * raycast_position.x > sin_cosine.x * raycast_position.y) ? dot(raycast_position.xy, sin_cosine) : length(raycast_position.xy);
	return sqrt(dot(raycast_position, raycast_position) + radius * radius - 2.0 * radius * k) - thickness;
}

float sdf3D_link(vec3 raycast_position, float len, float radius, float thickness)
{
	vec3 q = vec3(raycast_position.x, max(abs(raycast_position.y) - len, 0.0), raycast_position.z);
	return length(vec2(length(q.xy) - radius, q.z)) - thickness;
}

float sdf3D_infinite_cylinder(vec3 raycast_position, vec2 position_offset, float radius)
{
	return length(raycast_position.xz - position_offset) - radius;
}

float sdf3D_cone(vec3 raycast_position, float angle, float height)
{
	vec2 sin_cosine = vec2(sin(angle), cos(angle));
	vec2 q = height * vec2(sin_cosine.x / sin_cosine.y, -1.0);
	  
	vec2 w = vec2(length(raycast_position.xz), raycast_position.y);
	vec2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
	vec2 b = w - q * vec2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
	float k = sign(q.y);
	float d = min(dot(a, a), dot(b, b));
	float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
	return sqrt(d) * sign(s);
}

float sdf3D_infinite_cone(vec3 raycast_position, float angle)
{
	vec2 sin_cosine = vec2(sin(angle), cos(angle));
	
	vec2 q = vec2(length(raycast_position.xz), -raycast_position.y);
	float d = length(q - sin_cosine * max(dot(q, sin_cosine), 0.0));
	return d * ((q.x * sin_cosine.y - q.y * sin_cosine.x < 0.0) ? -1.0 : 1.0);
}

float sdf3D_plane(vec3 raycast_position, vec3 normal, float height)
{
	return dot(raycast_position, normal) + height;
}

float sdf3D_hexagonal_prism(vec3 raycast_position, float radius, float len)
{
	const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
	raycast_position = abs(raycast_position);
	raycast_position.xy -= 2.0 * min(dot(k.xy, raycast_position.xy), 0.0) * k.xy;
	vec2 d = vec2(
		length(raycast_position.xy - vec2(clamp(raycast_position.x, -k.z * radius, k.z * radius), radius)) * sign(raycast_position.y - radius),
		raycast_position.z - len);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdf3D_triangular_prism(vec3 raycast_position, float radius, float len)
{
	const float k = sqrt(3.0);
	
	radius *= 0.5* k;
	raycast_position.xy /= radius;
	raycast_position.x = abs(raycast_position.x) - 1.0;
	raycast_position.y = raycast_position.y + 1.0 / k;
	
	if (raycast_position.x + k * raycast_position.y > 0.0)
		raycast_position.xy = vec2(raycast_position.x - k * raycast_position.y, -k * raycast_position.x - raycast_position.y) / 2.0;
	
	raycast_position.x -= clamp(raycast_position.x, -2.0, 0.0);
	
	float d1 = length(raycast_position.xy) * sign(-raycast_position.y) * radius;
	float d2 = abs(raycast_position.z) - len;
	
	return length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.0);
}

float sdf3D_vertical_capsule(vec3 raycast_position, float height, float radius)
{
	raycast_position.y -= clamp(raycast_position.y, 0.0, height);
	return length(raycast_position) - radius;
}

float sdf3D_arbitrary_capsule(vec3 raycast_position, vec3 start, vec3 end, float radius)
{
	vec3 pa = raycast_position - start, ba = end - start;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - radius;
}

float sdf3D_vertical_capped_cylinder(vec3 raycast_position, float height, float radius)
{
	vec2 d = abs(vec2(length(raycast_position.xz), raycast_position.y)) - vec2(radius, height);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdf3D_arbitrary_capped_cylinder(vec3 raycast_position, vec3 start, vec3 end, float radius)
{
	vec3  ba = end - start;
	vec3  pa = raycast_position - start;
	float baba = dot(ba, ba);
	float paba = dot(pa, ba);
	float x = length(pa * baba - ba * paba) - radius * baba;
	float y = abs(paba - baba * 0.5) - baba * 0.5;
	float x2 = x * x;
	float y2 = y * y * baba;
	float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
	return sign(d) * sqrt(abs(d)) / baba;
}

float sdf3D_rounded_cylinder(vec3 raycast_position, float cylinder_radius, float rounding_radius, float height)
{
	vec2 d = vec2(length(raycast_position.xz) - 2.0 * cylinder_radius + rounding_radius, abs(raycast_position.y) - height);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rounding_radius;
}

float sdf3D_vertical_capped_cone(vec3 raycast_position, float height, float bottom_radius, float top_radius)
{
  vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
  vec2 k1 = vec2(top_radius, height);
  vec2 k2 = vec2(top_radius - bottom_radius, 2.0 * height);
  vec2 ca = vec2(q.x - min(q.x, (q.y < 0.0) ? bottom_radius : top_radius), abs(q.y) - height);
  vec2 cb = q - k1 + k2 * clamp(dot(k1-q,k2) / (dot(k2, k2)), 0.0, 1.0);
  float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
  return s * sqrt(min(dot(ca, ca), dot(cb, cb)));
}

float sdf3D_arbitrary_capped_cone(vec3 raycast_position, vec3 start, vec3 end, float bottom_radius, float top_radius)
{
	float rba  = top_radius - bottom_radius;
	float baba = dot(end - start, end - start);
	float papa = dot(raycast_position - start, raycast_position - start);
	float paba = dot(raycast_position - start, end - start) / baba;
	float x = sqrt(papa - paba * paba * baba);
	float cax = max(0.0, x - ((paba < 0.5) ? bottom_radius : top_radius));
	float cay = abs(paba-0.5)-0.5;
	float k = rba*rba + baba;
	float f = clamp((rba * (x - bottom_radius) + paba * baba) / k, 0.0, 1.0);
	float cbx = x - bottom_radius - f * rba;
	float cby = paba - f;
	float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
	return s * sqrt(min(cax*cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
}

float sdf3D_solid_angle(vec3 raycast_position, float angle, float radius)
{
	vec2 sin_cosine = vec2(sin(angle), cos(angle));
	vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
	float l = length(q) - radius;
	float m = length(q - sin_cosine * clamp(dot(q, sin_cosine), 0.0, radius));
	return max(l, m * sign(sin_cosine.y * q.x - sin_cosine.x * q.y));
}

float sdf3D_cut_sphere(vec3 raycast_position, float radius, float cut_depth)
{
	// sampling independent computations (only depend on shape)
	float w = sqrt(radius * radius - cut_depth * cut_depth);
	
	// sampling dependant computations
	vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
	float s = max((cut_depth - radius) * q.x * q.x + w * w * (cut_depth + radius - 2.0 * q.y), cut_depth * q.x - w * q.y);
	return (s < 0.0) ? length(q) - radius : (q.x < w) ? cut_depth - q.y : length(q - vec2(w, cut_depth));
}

float sdf3D_cut_hollow_sphere(vec3 raycast_position, float radius, float cut_depth, float thickness)
{
	// sampling independent computations (only depend on shape)
	float w = sqrt(radius * radius - cut_depth * cut_depth);
	
	// sampling dependant computations
	vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
	return ((cut_depth * q.x < w * q.y) ? length(q - vec2(w, cut_depth)) : abs(length(q) - radius)) - thickness;
}

float sdf3D_vertical_round_cone(vec3 raycast_position, float height, float bottom_radius, float top_radius)
{
	// sampling independent computations (only depend on shape)
	float b = (bottom_radius - top_radius) / height;
	float a = sqrt(1.0 - b * b);
	
	// sampling dependant computations
	vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
	float k = dot(q,vec2(-b, a));
	
	if (k < 0.0)
		return length(q) - bottom_radius;
	
	if (k > a * height)
		return length(q - vec2(0.0, height)) - top_radius;
	
	return dot(q, vec2(a, b)) - bottom_radius;
}

float sdf3D_arbitrary_round_cone(vec3 raycast_position, vec3 start, vec3 end, float bottom_radius, float top_radius)
{
	// sampling independent computations (only depend on shape)
	vec3  ba = end - start;
	float l2 = dot(ba,ba);
	float rr = bottom_radius - top_radius;
	float a2 = l2 - rr * rr;
	float il2 = 1.0 / l2;
	  
	// sampling dependant computations
	vec3 pa = raycast_position - start;
	float y = dot(pa, ba);
	float z = y - l2;
	float x2 = dot(pa * l2 - ba * y, pa * l2 - ba * y);
	float y2 = y * y * l2;
	float z2 = z * z * l2;
	
	// single square root!
	float k = sign(rr) * rr * rr * x2;
	
	if (sign(z) * a2 * z2 > k)
		return sqrt(x2 + z2) * il2 - top_radius;
	
	if (sign(y) * a2 * y2 < k)
		return sqrt(x2 + y2) * il2 - bottom_radius;
	
	return (sqrt(x2 * a2 * il2) + y * rr) * il2 - bottom_radius;
}

float sdf3D_ellipsoid_bound(vec3 raycast_position, vec3 radii)
{
	float k0 = length(raycast_position / radii);
	float k1 = length(raycast_position / (radii * radii));
	return k0 * (k0 - 1.0) / k1;
}

float sdf3D_vertical_vesica_segment(vec3 raycast_position, float height, float weight)
{
	// shape constants
	height *= 0.5;
	weight *= 0.5;
	float d = 0.5 * (height * height - weight * weight) / weight;
	
	// project to 2D
	vec2 q = vec2(length(raycast_position.xz), abs(raycast_position.y - height));
	
	// feature selection (vertex or body)
	vec3 t = (height * q.x < d * (q.y - height)) ? vec3(0.0, height, 0.0) : vec3(-d, 0.0, d + weight);
	
	// distance
	return length(q - t.xy) - t.z;
}

float sdf3D_arbitrary_vesica_segment(vec3 raycast_position, vec3 start, vec3 end, float weight)
{
	// orient and project to 2D
	vec3  c = (start + end) * 0.5;
	float h = length(end - start);
	vec3  v = (end - start) / h;
	float y = dot(raycast_position - c, v);
	vec2  q = vec2(length(raycast_position - c - y * v), abs(y));
	
	// shape constants
	h *= 0.5;
	weight *= 0.5;
	float d = 0.5 * (h * h - weight * weight) / weight;
	
	// feature selection (vertex or body)
	vec3 t = (h * q.x < d * (q.y - h)) ? vec3(0.0, h, 0.0) : vec3(-d, 0.0, d + weight);
	
	// distance
	return length(q - t.xy) - t.z;
}

float sdf3D_rhombus(vec3 raycast_position, float vertical_length, float horizontal_length, float height, float radius)
{
	raycast_position = abs(raycast_position);
	vec2 b = vec2(vertical_length, horizontal_length);
	vec2 b_offset = b - 2.0 * raycast_position.xz;
	float ndot = b.x * b_offset.x - b.y * b_offset.y;
	float f = clamp(ndot / dot(b, b), -1.0, 1.0);
	vec2 q = vec2(length(raycast_position.xz - 0.5 * b * vec2(1.0 - f, 1.0 + f)) * sign(raycast_position.x * b.y + raycast_position.z * b.x - b.x * b.y) - radius, raycast_position.y - height);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0));
}

float sdf3D_octahedron(vec3 raycast_position, float rounding_radius)
{
	raycast_position = abs(raycast_position);
	
	float m = raycast_position.x + raycast_position.y + raycast_position.z - rounding_radius;
	vec3 q;
	
	if (3.0 * raycast_position.x < m)
		q = raycast_position.xyz;
	else if (3.0 * raycast_position.y < m)
		q = raycast_position.yzx;
	else if (3.0 * raycast_position.z < m)
		q = raycast_position.zxy;
	else
		return m * 0.57735027;
	  
	float k = clamp(0.5 * (q.z - q.y + rounding_radius), 0.0, rounding_radius);
	return length(vec3(q.x, q.y - rounding_radius + k, q.z - k));
}

float sdf3D_pyramid(vec3 raycast_position, float height)
{
	float m2 = height * height + 0.25;
	  
	raycast_position.xz = abs(raycast_position.xz);
	raycast_position.xz = (raycast_position.z > raycast_position.x) ? raycast_position.zx : raycast_position.xz;
	raycast_position.xz -= 0.5;
	
	vec3 q = vec3(raycast_position.z, height * raycast_position.y - 0.5 * raycast_position.x, height * raycast_position.x + 0.5 * raycast_position.y);
	 
	float s = max(-q.x,0.0);
	float t = clamp((q.y - 0.5 * raycast_position.z) / (m2 + 0.25), 0.0, 1.0);
	  
	float a = m2 * (q.x + s) *(q.x + s) + q.y * q.y;
	float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);
	  
	float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);
	  
	return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -raycast_position.y));
}

float sdf3D_generate(vec3 raycast_position, int shape, vec4 args1, vec4 args2)
{
	float sdf = INFINITY;

	switch (shape)
	{
		case SDF3D_SHAPE_SPHERE:
            sdf = sdf3D_sphere(raycast_position, args1.x);
			break;

		case SDF3D_SHAPE_BOX:
            sdf = sdf3D_box(raycast_position, args1.xyz);
			break;

		case SDF3D_SHAPE_ROUNDED_BOX:
            sdf = sdf3D_rounded_box(raycast_position, args1.xyz, args1.w);
			break;

		case SDF3D_SHAPE_BOX_FRAME:
            sdf = sdf3D_rounded_box(raycast_position, args1.xyz, args1.w);
			break;

		case SDF3D_SHAPE_TORUS:
            sdf = sdf3D_torus(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_CAPPED_TORUS:
            sdf = sdf3D_capped_torus(raycast_position, args1.x, args1.y, args1.z);
			break;

		case SDF3D_SHAPE_LINK:
            sdf = sdf3D_link(raycast_position, args1.x, args1.y, args1.z);
			break;

		case SDF3D_SHAPE_INFINITE_CYLINDER:
            sdf = sdf3D_infinite_cylinder(raycast_position, args1.xy, args1.z);
			break;

		case SDF3D_SHAPE_CONE:
            sdf = sdf3D_cone(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_INFINITE_CONE:
            sdf = sdf3D_infinite_cone(raycast_position, args1.x);
			break;

		case SDF3D_SHAPE_PLANE:
            sdf = sdf3D_plane(raycast_position, args1.xyz, args1.w);
			break;

		case SDF3D_SHAPE_HEXAGONAL_PRISM:
            sdf = sdf3D_hexagonal_prism(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_TRIANGULAR_PRISM:
            sdf = sdf3D_triangular_prism(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_VERTICAL_CAPSULE:
            sdf = sdf3D_vertical_capsule(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_ARBITRARY_CAPSULE:
            sdf = sdf3D_arbitrary_capsule(raycast_position, args1.xyz, vec3(args1.w, args2.x, args2.y), args2.z);
			break;

		case SDF3D_SHAPE_VERTICAL_CAPPED_CYLINDER:
            sdf = sdf3D_vertical_capped_cylinder(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_ARBITRARY_CAPPED_CYLINDER:
            sdf = sdf3D_arbitrary_capped_cylinder(raycast_position, args1.xyz, vec3(args1.w, args2.x, args2.y), args2.z);
			break;

		case SDF3D_SHAPE_ROUNDED_CYLINDER:
            sdf = sdf3D_rounded_cylinder(raycast_position, args1.x, args1.y, args1.z);
			break;

		case SDF3D_SHAPE_VERTICAL_CAPPED_CONE:
            sdf = sdf3D_vertical_capped_cone(raycast_position, args1.x, args1.y, args1.z);
			break;

		case SDF3D_SHAPE_ARBITRARY_CAPPED_CONE:
            sdf = sdf3D_arbitrary_capped_cone(raycast_position, args1.xyz, vec3(args1.w, args2.x, args2.y), args2.z, args2.w);
			break;

		case SDF3D_SHAPE_SOLID_ANGLE:
            sdf = sdf3D_solid_angle(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_CUT_SPHERE:
            sdf = sdf3D_cut_sphere(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_CUT_HOLLOW_SPHERE:
            sdf = sdf3D_cut_hollow_sphere(raycast_position, args1.x, args1.y, args1.z);
			break;

		case SDF3D_SHAPE_VERTICAL_ROUND_CONE:
            sdf = sdf3D_vertical_round_cone(raycast_position, args1.x, args1.y, args1.z);
			break;

		case SDF3D_SHAPE_ARBITRARY_ROUND_CONE:
            sdf = sdf3D_arbitrary_round_cone(raycast_position, args1.xyz, vec3(args1.w, args2.x, args2.y), args2.z, args2.w);
			break;

		case SDF3D_SHAPE_ELLIPSOID_BOUND:
            sdf = sdf3D_ellipsoid_bound(raycast_position, args1.xyz);
			break;

		case SDF3D_SHAPE_VERTICAL_VESICA_SEGMENT:
            sdf = sdf3D_vertical_vesica_segment(raycast_position, args1.x, args1.y);
			break;

		case SDF3D_SHAPE_ARBITRARY_VESICA_SEGMENT:
            sdf = sdf3D_arbitrary_vesica_segment(raycast_position, args1.xyz, vec3(args1.w, args2.x, args2.y), args2.z);
			break;

		case SDF3D_SHAPE_RHOMBUS:
            sdf = sdf3D_rhombus(raycast_position, args1.x, args1.y, args1.z, args1.w);
			break;

		case SDF3D_SHAPE_OCTAHEDRON:
            sdf = sdf3D_octahedron(raycast_position, args1.x);
			break;

		case SDF3D_SHAPE_PYRAMID:
            sdf = sdf3D_pyramid(raycast_position, args1.x);
			break;

		default:
			break;
	}

	return sdf;
}

// -------------------------------------------------------------------
// Combinations
// -------------------------------------------------------------------

const int SDF3D_COMBINATION_UNION = 0;
const int SDF3D_COMBINATION_XOR = SDF3D_COMBINATION_UNION + 1;
const int SDF3D_COMBINATION_SUBTRACTION = SDF3D_COMBINATION_XOR + 1;
const int SDF3D_COMBINATION_INTERSECTION = SDF3D_COMBINATION_SUBTRACTION + 1;
const int SDF3D_COMBINATION_SMOOTH_UNION = SDF3D_COMBINATION_INTERSECTION + 1;
const int SDF3D_COMBINATION_SMOOTH_SUBTRACTION = SDF3D_COMBINATION_SMOOTH_UNION + 1;
const int SDF3D_COMBINATION_SMOOTH_INTERSECTION = SDF3D_COMBINATION_SMOOTH_SUBTRACTION + 1;
const int SDF3D_COMBINATION_CHAMFER_UNION = SDF3D_COMBINATION_SMOOTH_INTERSECTION + 1;
const int SDF3D_COMBINATION_CHAMFER_SUBTRACTION = SDF3D_COMBINATION_CHAMFER_UNION + 1;
const int SDF3D_COMBINATION_CHAMFER_INTERSECTION = SDF3D_COMBINATION_CHAMFER_SUBTRACTION + 1;
const int SDF3D_COMBINATION_ROUND_UNION = SDF3D_COMBINATION_CHAMFER_INTERSECTION + 1;
const int SDF3D_COMBINATION_ROUND_SUBTRACTION = SDF3D_COMBINATION_ROUND_UNION + 1;
const int SDF3D_COMBINATION_ROUND_INTERSECTION = SDF3D_COMBINATION_ROUND_SUBTRACTION + 1;
const int SDF3D_COMBINATION_SOFT_UNION = SDF3D_COMBINATION_ROUND_INTERSECTION + 1;
const int SDF3D_COMBINATION_PIPE = SDF3D_COMBINATION_SOFT_UNION + 1;
const int SDF3D_COMBINATION_ENGRAVE = SDF3D_COMBINATION_PIPE + 1;
const int SDF3D_COMBINATION_GROOVE = SDF3D_COMBINATION_ENGRAVE + 1;
const int SDF3D_COMBINATION_TONGUE = SDF3D_COMBINATION_GROOVE + 1;
const int SDF3D_COMBINATION_COLUMNS_UNION = SDF3D_COMBINATION_TONGUE + 1;
const int SDF3D_COMBINATION_COLUMNS_SUBTRACTION = SDF3D_COMBINATION_COLUMNS_UNION + 1;
const int SDF3D_COMBINATION_COLUMNS_INTERSECTION = SDF3D_COMBINATION_COLUMNS_SUBTRACTION + 1;
const int SDF3D_COMBINATION_STAIRS_UNION = SDF3D_COMBINATION_COLUMNS_INTERSECTION + 1;
const int SDF3D_COMBINATION_STAIRS_SUBTRACTION = SDF3D_COMBINATION_STAIRS_UNION + 1;
const int SDF3D_COMBINATION_STAIRS_INTERSECTION = SDF3D_COMBINATION_STAIRS_SUBTRACTION + 1;

// The following functions are taken from the Mercury Demogroup's hg_sdf file:
// https://mercury.sexy/hg_sdf/
// Licensed under the MIT License.

vec2 _p_rot_45(vec2 p)
{
	return (p + vec2(p.y, -p.x)) * sqrt(0.5);
}

vec2 _p_mod_1(float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p + halfsize) / size);
	return vec2(mod(p + halfsize, size) - halfsize, c);
}

float _columns_union(float a, float b, float r, float n)
{
	if ((a < r) && (b < r))
    {
		vec2 p = vec2(a, b);
		float column_radius = r * sqrt(2) / ((n - 1) * 2 + sqrt(2));

        p = _p_rot_45(p);
		p.x -= sqrt(2) / 2 * r;
		p.x += column_radius * sqrt(2);

		if (mod(n, 2) == 1)
			p.y += column_radius;
        
		// At this point, we have turned 45 degrees and moved at a point on the
		// diagonal that we want to place the columns on.
		// Now, repeat the domain along this direction and place a circle.
        p.y = _p_mod_1(p.y, column_radius * 2).x;

		float result = length(p) - column_radius;
		
        result = min(result, p.x);
		result = min(result, a);

		return min(result, b);
    }

    return min(a, b);
}

// End License

float _columns_subtraction(float a, float b, float r, float n)
{
	a = -a;
	float m = min(a, b);

	//avoid the expensive computation where not needed (produces discontinuity though)
	if ((a < r) && (b < r))
    {
		vec2 p = vec2(a, b);
		float column_radius = r * sqrt(2) / n / 2.0;
		column_radius = r * sqrt(2) / ((n - 1) * 2 + sqrt(2));

        p = _p_rot_45(p);
		p.y += column_radius;
		p.x -= sqrt(2) / 2 * r;
		p.x += -column_radius * sqrt(2) / 2;

		if (mod(n, 2) == 1)
			p.y += column_radius;
        
        p.y = _p_mod_1(p.y, column_radius * 2).x;

		float result = -length(p) + column_radius;

		result = max(result, p.x);
		result = min(result, a);

		return -min(result, b);
	}

    return -m;
}

float _stairs_union(float a, float b, float r, float n)
{
	float s = r / n;
	float u = b - r;
	return min(min(a, b), 0.5 * (u + a + abs((mod(u - a + s, 2 * s)) - s)));
}

float sdf3D_combine(float sdf1, float sdf2, vec4 args)
{
    float sdf = sdf1;

    float first_radius = args.y;
    float second_radius = args.z;
    float steps = args.w;

    float h; // HUE HUE HUE
    vec2 u;
    float e;

    switch (int(args.x))
    {
        // The following functions (including Union) are taken from Inigo Quilez's article on 3D SDFs
		// https://iquilezles.org/articles/distfunctions/
		// Licensed under the MIT License.

        case SDF3D_COMBINATION_XOR:
            sdf = max(min(sdf1, sdf2), -max(sdf1, sdf2));
            break;
        
        case SDF3D_COMBINATION_SUBTRACTION:
            sdf = max(-sdf1, sdf2);
            break;
        
        case SDF3D_COMBINATION_INTERSECTION:
            sdf = max(sdf1, sdf2);
            break;
        
        case SDF3D_COMBINATION_SMOOTH_UNION:
            h = clamp(0.5 + 0.5 * (sdf2 - sdf1) / first_radius, 0.0, 1.0);
			sdf = mix(sdf2, sdf1, h) - first_radius * h * (1.0 - h);
            break;
        
        case SDF3D_COMBINATION_SMOOTH_SUBTRACTION:
            h = clamp(0.5 - 0.5 * (sdf2 + sdf1) / first_radius, 0.0, 1.0);
			sdf = mix(sdf2, -sdf1, h) + first_radius * h * (1.0 - h);
            break;
        
        case SDF3D_COMBINATION_SMOOTH_INTERSECTION:
            h = clamp(0.5 - 0.5 * (sdf2 - sdf1) / first_radius, 0.0, 1.0);
			sdf = mix(sdf2, sdf1, h) + first_radius * h * (1.0 - h);
            break;

        // The following functions are taken from the Mercury Demogroup's hg_sdf file:
		// https://mercury.sexy/hg_sdf/
		// Licensed under the MIT License.
        
        case SDF3D_COMBINATION_CHAMFER_UNION:
            sdf = min(min(sdf2, sdf1), (sdf2 - first_radius + sdf1) * sqrt(0.5));
            break;
        
        case SDF3D_COMBINATION_CHAMFER_SUBTRACTION:
            sdf = max(max(sdf2, -sdf1), (sdf2 + first_radius + -sdf1) * sqrt(0.5));
            break;
        
        case SDF3D_COMBINATION_CHAMFER_INTERSECTION:
            sdf = max(max(sdf2, sdf1), (sdf2 + first_radius + sdf1) * sqrt(0.5));
            break;
        
        case SDF3D_COMBINATION_ROUND_UNION:
            u = max(vec2(first_radius - sdf2, first_radius - sdf1), 0.0);
			sdf = max(first_radius, min(sdf2, sdf1)) - length(u);
            break;
        
        case SDF3D_COMBINATION_ROUND_SUBTRACTION:
            u = max(vec2(first_radius + sdf2, first_radius + -sdf1), 0.0);
			sdf = min(-first_radius, max(sdf2, -sdf1)) + length(u);
            break;
        
        case SDF3D_COMBINATION_ROUND_INTERSECTION:
            u = max(vec2(first_radius + sdf2, first_radius + sdf1), 0.0);
			sdf = min(-first_radius, max(sdf2, sdf1)) + length(u);
            break;
        
        case SDF3D_COMBINATION_SOFT_UNION:
            e = max(first_radius - abs(sdf2 - sdf1), 0.0);
			sdf = min(sdf2, sdf1) - e * e * 0.25 / first_radius;
            break;
        
        case SDF3D_COMBINATION_PIPE:
            sdf = length(vec2(sdf2, sdf1)) - first_radius;
            break;
        
        case SDF3D_COMBINATION_ENGRAVE:
            sdf = max(sdf2, (sdf2 + first_radius - abs(sdf1)) * sqrt(0.5));
            break;
        
        case SDF3D_COMBINATION_GROOVE:
            sdf = max(sdf2, min(sdf2 + first_radius, second_radius - abs(sdf1)));
            break;
        
        case SDF3D_COMBINATION_TONGUE:
            sdf = min(sdf2, max(sdf2 - first_radius, abs(sdf1) - second_radius));
            break;
        
        case SDF3D_COMBINATION_COLUMNS_UNION:
            sdf = _columns_union(sdf2, sdf1, first_radius, steps);
            break;
        
        case SDF3D_COMBINATION_COLUMNS_SUBTRACTION:
            sdf = _columns_subtraction(sdf2, sdf1, first_radius, steps);
            break;
        
        case SDF3D_COMBINATION_COLUMNS_INTERSECTION:
            sdf = _columns_subtraction(sdf2, -sdf1, first_radius, steps);
            break;
        
        case SDF3D_COMBINATION_STAIRS_UNION:
            sdf = _stairs_union(sdf2, sdf1, first_radius, steps);
            break;
        
        case SDF3D_COMBINATION_STAIRS_SUBTRACTION:
            sdf = -_stairs_union(-sdf2, sdf1, first_radius, steps);
            break;
        
        case SDF3D_COMBINATION_STAIRS_INTERSECTION:
            sdf = -_stairs_union(-sdf2, -sdf1, first_radius, steps);
            break;

        default:
            sdf = min(sdf1, sdf2);
            break;
    }

    return sdf;
}

// -------------------------------------------------------------------
// Scene Generation
// -------------------------------------------------------------------

float sample_scene(vec3 position)
{
    float sdf = INFINITY;

    for (int i = 0; i < static_params.num_shapes; i++)
        sdf = sdf3D_combine(sdf3D_generate(position, shape_types.types[i], shape_params.params[i], shape_params.params[i + 1]), sdf, combinations.types_and_params[i]);

    return sdf;
}

bool vec3i_equals(vec3 a, vec3 b)
{
    return uint(a.x) == uint(b.x) && uint(a.y) == uint(b.y) && uint(a.z) == uint(b.z);
}

// From Mikola Lysenko's JS implementation of surface nets
// https://github.com/mikolalysenko/mikolalysenko.github.com/blob/master/Isosurface/js/surfacenets.js
// Licensed under the MIT License.
// void create_surface_nets(uint invocation, vec3 position)
void create_surface_nets()
{
    int cube_edges[24] = {
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0
    };

    int edge_table[256] = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    };

    // Create the cube edges

    int table_iterator = 0;

    for (int i = 0; i < 8; i++)
    {
        int j = 1;

        while (j <= 4)
        {
            int p = i ^ j;

            if (i <= p)
            {
                cube_edges[table_iterator++] = i;
                cube_edges[table_iterator++] = p;
            }

            j <<= 1;
        }
    }

    // Create the intersection table

    table_iterator = 0;

    for (int i = 0; i < 256; i++)
    {
        int edge_mask = 0;

        for (int j = 0; j < 24; j += 2)
        {
            bool a = bool(i & (1 << cube_edges[j]));
            bool b = bool(i & (1 << cube_edges[j + 1]));

            edge_mask |= a != b ? (1 << (j >> 1)) : 0;
        }
    }

    // Create the surface nets

    int n = 0;
    int R[3] = { 1, int(static_params.dimensions.x) + 1, (int(static_params.dimensions.x) + 1) * (int(static_params.dimensions.y) + 1) };
    float grid[8] = { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 };
    int buffer_number = 1;
    int vertices_size = 0;

    for (int pos_z = 0; pos_z < int(static_params.dimensions.z) - 1; pos_z++, n += int(static_params.dimensions.x), buffer_number ^= 1, R[2] = -R[2])
    {
        int buffer_index = 1 + int(static_params.dimensions.z + 1) * int(1 + buffer_number * (static_params.dimensions.y + 1));

        for (int pos_y = 0; pos_y < int(static_params.dimensions.y) - 1; pos_y++, n += 1, buffer_index += 2)
        {
            for (int pos_x = 0; pos_x < int(static_params.dimensions.x); pos_x++, n += 1, buffer_index += 1)
            {
                vec3 cur_pos = vec3(pos_x, pos_y, pos_z);
                
                vertices.points[vertices_size] = cur_pos;

                int mask = 0;
                int grid_pos = 0;
                int sample_index = n;

                // Read in 8 SDF samples around this vertex and store them in an array
                // Also calculate 8-bit mask, like in marching cubes, so we can speed up sign checks later
                for (int k = 0; k < 2; k++, sample_index += int(static_params.dimensions.x) * (int(static_params.dimensions.y) - 2))
                {
                    for (int j = 0; j < 2; j++, sample_index += int(static_params.dimensions.x) - 2)
                    {
                        for (int i = 0; i < 2; i++, grid_pos += 1, sample_index += 1)
                        {
                            float sampling = sample_scene(cur_pos); // REMARK: Will re-calculating cause slowdowns? I wonder...
                            grid[grid_pos] = sampling;
                            mask |= sampling < 0.0 ? (1 << grid_pos) : 0;
                        }
                    }
                }

                // Check for early termination if cell does not intersect boundary
                if (mask == 0 || mask == 0xFF)
                    continue;

                int edge_mask = edge_table[mask];
                vec3 vertex = vec3(0.0);
                int edge_count = 0;

                // For every edge of the cube...
                for (int i = 0; i < 12; i++)
                {
                    // Use edge mask to check if it is crossed
                    if (!bool(edge_mask & (1 << i)))
                        continue;
                    
                    // If it did, increment number of edge crossings
                    edge_count += 1;
                    
                    // Find the point of intersection
                    
                    // Unpack vertices
                    int edge0 = cube_edges[i << 1];
                    int edge1 = cube_edges[(i << 1) + 1];
                    // Unpack grid values
                    float grid0 = grid[edge0];
                    float grid1 = grid[edge1];
                    // Compute point of intersection
                    float t = grid0 - grid1;
                    
                    if (abs(t) > 1e-6)
                        t = grid0 / t;
                    else
                        continue;
                    
                    // Interpolate vertices and add up intersections (this can be done without multiplying)
                    int k = 1;
                    
                    for (int j = 0; j < 3; j++)
                    {
                        int a = edge0 & k;
                        int b = edge1 & k;
                        
                        if (a != b)
                            vertex[j] += bool(a) ? 1.0 - t : t;
                        else
                            vertex[j] += bool(a) ? 1.0 : 0.0;
                        
                        k <<= 1;
                    }
                }

                // Average the edge intersections and add them to the coordinate
                float s = 1.0 / float(edge_count);
                vertex = static_params.sample_space_position + (cur_pos * static_params.sample_space_size / static_params.dimensions) + s * vertex;

                // REMARK: I don't think rewriting the vertices size to the same buffer index
                // will break anything, but this is the first time I've used a compute shader
                // for real so idk
                surface_nets_buffer.buf[buffer_index] = vertices_size;

                vertices.points[vertices_size] = vertex;
                // sample_positions.points[vertices_size] = cur_pos;

                // Add faces together by looping over the 3 basis components
                for (int i = 0; i < 3; i++)
                {
                    // The first three entries of the edge_mask count the crossings along the edge
                    if (!bool(edge_mask & (1 << i)))
                        continue;
                    
                    // i = axis pointing along; iu, iv = orthogonal axes
                    int iu = (i + 1) % 3;
                    int iv = (i + 2) % 3;
                    
                    // Skip if on a boundary
                    if (int(cur_pos[iu]) == 0 || int(cur_pos[iv]) == 0)
                        continue;
                    
                    // Otherwise look up adjacent edges in the buffer
                    int du = R[iu];
                    int dv = R[iv];
                    
                    // Flip orientation depending on the sign of the corner
                    if (bool(mask & 1))
                    {
                        triangles.indices[gl_GlobalInvocationID.x]     = surface_nets_buffer.buf[buffer_index];
                        triangles.indices[gl_GlobalInvocationID.x + 1] = surface_nets_buffer.buf[buffer_index - du - dv];
                        triangles.indices[gl_GlobalInvocationID.x + 2] = surface_nets_buffer.buf[buffer_index - du];
                        triangles.indices[gl_GlobalInvocationID.x + 3] = surface_nets_buffer.buf[buffer_index];
                        triangles.indices[gl_GlobalInvocationID.x + 4] = surface_nets_buffer.buf[buffer_index - dv];
                        triangles.indices[gl_GlobalInvocationID.x + 5] = surface_nets_buffer.buf[buffer_index - du - dv];
                    }
                    else
                    {
                        triangles.indices[gl_GlobalInvocationID.x]     = surface_nets_buffer.buf[buffer_index];
                        triangles.indices[gl_GlobalInvocationID.x + 1] = surface_nets_buffer.buf[buffer_index - du - dv];
                        triangles.indices[gl_GlobalInvocationID.x + 2] = surface_nets_buffer.buf[buffer_index - dv];
                        triangles.indices[gl_GlobalInvocationID.x + 3] = surface_nets_buffer.buf[buffer_index];
                        triangles.indices[gl_GlobalInvocationID.x + 4] = surface_nets_buffer.buf[buffer_index - du];
                        triangles.indices[gl_GlobalInvocationID.x + 5] = surface_nets_buffer.buf[buffer_index - du - dv];
                    }
                }

                vertices_size++;
            }
        }
    }
}

// The code we want to execute in each invocation
void main()
{
    // vec3 position = vec3(
    //     gl_GlobalInvocationID.x % uint(static_params.dimensions.x),
    //     gl_GlobalInvocationID.x / uint(static_params.dimensions.x),
    //     gl_GlobalInvocationID.x / uint(static_params.dimensions.x) / uint(static_params.dimensions.y)
    // );
    
    // if (position.x < static_params.dimensions.x && position.y < static_params.dimensions.y && position.z < static_params.dimensions.z)
        // create_surface_nets(gl_GlobalInvocationID.x, position);
    create_surface_nets();
}