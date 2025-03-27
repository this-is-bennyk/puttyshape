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

shader_type spatial;
render_mode world_vertex_coords, shadows_disabled;

#include "PuttyGenerationLibrary3D.gdshaderinc"

const int MAX_SHADOW_STEPS = 256;

uniform int max_steps : hint_range(1, 1000, 1) = 150;
uniform float min_distance : hint_range(0.0, 1e12, 0.1) = 0.0;
uniform float max_distance : hint_range(1.0, 1e12, 0.1) = 256.0;
uniform float surface_distance : hint_range(0.01, 1.0, 0.01) = 0.01;

uniform int num_shapes = 0;

// TODO: 9 texel reads is a lot... anyway to optimize down for a variable number of shapes?
// [0]: X: Shape type; Y: # Modifications (unimplemented), Z: Material index (unimplemented)
// [1]: Affine inverse of global transform X
// [2]: Affine inverse of global transform Y
// [3]: Affine inverse of global transform Z
// [4]: Affine inverse of global transform Origin
// [5]: Shape data #1
// [6]: Shape data #2
// [7]: XYZ: Scale
// [8]: X: Combination type, Y: First radius; Z: Second radius; W: Steps
// [9]: Color
uniform sampler2D shape_data;

//uniform sampler2D modification_data;

struct Surface
{
	float sdf;
	vec4 color;
};

Surface putty3D_get_scene(vec3 raycast_position)
{
	const float INFINITY = 3.402823466e38;
	float sdf = INFINITY;
	//int closest_material_idx = -1;
	vec4 closest_color = vec4(1.0);
	
	ivec2 shape_data_size = textureSize(shape_data, 0);

	#define ZERO int(min(TIME, 0.0)) // Non-constant zero to prevent inlining
	for (int shape_idx = ZERO; shape_idx < num_shapes; shape_idx++)
	{
		int shape_position = shape_idx * 10;
		vec4 shape_info = texelFetch(shape_data, ivec2((shape_position + 0) % shape_data_size.x, (shape_position + 0) / shape_data_size.x), 0);

		mat4 transform = mat4(
			texelFetch(shape_data, ivec2((shape_position + 1) % shape_data_size.x, (shape_position + 1) / shape_data_size.x), 0),
			texelFetch(shape_data, ivec2((shape_position + 2) % shape_data_size.x, (shape_position + 2) / shape_data_size.x), 0),
			texelFetch(shape_data, ivec2((shape_position + 3) % shape_data_size.x, (shape_position + 3) / shape_data_size.x), 0),
			texelFetch(shape_data, ivec2((shape_position + 4) % shape_data_size.x, (shape_position + 4) / shape_data_size.x), 0)
		);

		vec4 shape_data1 = texelFetch(shape_data, ivec2((shape_position + 5) % shape_data_size.x, (shape_position + 5) / shape_data_size.x), 0);
		vec4 shape_data2 = texelFetch(shape_data, ivec2((shape_position + 6) % shape_data_size.x, (shape_position + 6) / shape_data_size.x), 0);
		vec4 scale       = texelFetch(shape_data, ivec2((shape_position + 7) % shape_data_size.x, (shape_position + 7) / shape_data_size.x), 0);
		vec4 combo_data  = texelFetch(shape_data, ivec2((shape_position + 8) % shape_data_size.x, (shape_position + 8) / shape_data_size.x), 0);

		float result = putty3D_generate(
			  raycast_position
			, int(shape_info.x)
			, transform
			, min(scale.x, min(scale.y, scale.z))
			, shape_data1
			, shape_data2
		);

		float prev_sdf = sdf;
		
		sdf = putty3D_combine(result, sdf, combo_data);
		
		if (result < prev_sdf)
			closest_color = texelFetch(shape_data, ivec2((shape_position + 9) % shape_data_size.x, (shape_position + 9) / shape_data_size.x), 0);
	}
	#undef ZERO

	return Surface(sdf, closest_color);
}

Surface putty3D_raymarch(vec3 ray_origin, vec3 ray_dir)
{
	float dist_from_origin = min_distance;
	Surface current_dist_info = Surface(0.0, vec4(1.0));

	#define ZERO int(min(TIME, 0.0)) // Non-constant zero to prevent inlining
	for (int i = ZERO; i < max_steps; i++)
	{
		vec3 raycast_position = ray_origin + ray_dir * dist_from_origin;

		current_dist_info = putty3D_get_scene(raycast_position);
		dist_from_origin += current_dist_info.sdf;

		// If we hit a surface or didn't hit anything, break out the loop
		if (current_dist_info.sdf < surface_distance || dist_from_origin > max_distance)
			break;
	}
	#undef ZERO

	return Surface(dist_from_origin, current_dist_info.color);
}

// From Inigo Quilez on normals
// https://iquilezles.org/articles/normalsSDF/
// Licensed under the MIT License.
vec3 putty3D_get_normal(vec3 raycast_position)
{
	const float NORMAL_EPSILON = 0.01;
	vec3 normal = vec3(0.0);

	#define ZERO int(min(TIME, 0.0)) // Non-constant zero to prevent inlining
	for (int i = ZERO; i < 4; i++)
	{
		vec3 e = 0.5773 * (2.0 * vec3(float(((i + 3) >> 1) & 1), float((i >> 1) & 1), float(i & 1))-1.0);
		normal += e * putty3D_get_scene(raycast_position + e * NORMAL_EPSILON).sdf;
	}
	#undef ZERO

	return normalize(normal);
}

float putty3D_get_soft_shadows(vec3 ray_origin, vec3 ray_dir, float light_size_steradians)
{
	float result = 1.0;
	float t = min_distance;

	#define ZERO int(min(TIME, 0.0)) // Non-constant zero to prevent inlining
	for(int i = ZERO; i < MAX_SHADOW_STEPS && t < max_distance; i++)
	{
		float h = putty3D_get_scene(ray_origin + ray_dir * t).sdf;

		result = min(result, h / (light_size_steradians * t));
		t += clamp(h, 0.005, 0.50);

		if (result < -1.0 || t > max_distance)
			break;
	}
	#undef ZERO
	
	result = max(result, -1.0);
	return 0.25 * (1.0 + result) * (1.0 + result) * (2.0 - result);
}

// Vertex/fragment: Portions taken from SSD's Godot Ray Marching plugin
// https://gitlab.com/the-SSD/godot-ray-marching/-/blob/main/addons/ray_marching/shaders/main.gdshader
// Licensed under the MIT License.

varying vec3 vert;
varying vec3 ray_origin;

void vertex()
{
	vert = vec4(VERTEX, 1.0).xyz;
	ray_origin = INV_VIEW_MATRIX[3].xyz;
}

void fragment()
{
	if (num_shapes <= 0)
		discard;
	else
	{
		vec3 ray_dir = normalize(vert - ray_origin);

		Surface surface = putty3D_raymarch(ray_origin, ray_dir);

		if (surface.sdf > max_distance)
			discard;
		else
		{
			vec3 raycast_position = ray_origin + ray_dir * surface.sdf;
			vec3 normal = putty3D_get_normal(raycast_position);
			mat3 view_matrix = mat3(VIEW_MATRIX);

			NORMAL = view_matrix * normal;
			LIGHT_VERTEX = view_matrix * raycast_position;
			
			//NORMAL = vec3(0.0);
			//LIGHT_VERTEX = vec3(0.0);

			vec4 sdf_ndc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(raycast_position, 1.0);

			#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
			DEPTH = (sdf_ndc.z / sdf_ndc.w) * 0.5 + 0.5;
			#else
			DEPTH = (sdf_ndc.z / sdf_ndc.w);
			#endif
			
			ALBEDO = surface.color.rgb;
		}
	}
}
