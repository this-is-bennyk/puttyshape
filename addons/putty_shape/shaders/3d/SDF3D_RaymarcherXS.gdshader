shader_type spatial;

const int MAX_STEPS = 150;
const float MAX_DISTANCE = 1000.0;
const float SURFACE_DISTANCE = 0.01;

const int MAX_SHAPES = 127;
const int MAX_PAGE_SIZE = MAX_SHAPES * 2;

uniform int shapes[MAX_SHAPES];
uniform float scales[MAX_SHAPES];
uniform int combinations[MAX_SHAPES];
uniform float smoothing_radii[MAX_SHAPES];
uniform int num_shapes = 0;

uniform vec4 data[MAX_PAGE_SIZE];
uniform mat4 transforms[MAX_SHAPES];

#include "SDF3D_Library.gdshaderinc"

uniform sampler2D depth_texture : hint_depth_texture;

float sdf3D_get_scene(vec3 raycast_position)
{
	const float INFINITY = 3.402823466e38;
	float sdf = INFINITY;
	float result;
	float smoothing_radius;

	for (int shape_idx = 0; shape_idx < num_shapes; shape_idx++)
	{
		result = sdf3D_generate(
			  raycast_position
			, shapes[shape_idx]
			, transforms[shape_idx]
			, scales[shape_idx]
			, sdf
			, data[shape_idx * 2]
			, data[(shape_idx * 2) + 1]
		);

		sdf = sdf3D_combine(result, sdf, combinations[shape_idx], smoothing_radii[shape_idx]);
	}

	return sdf;
}

float sdf3D_raymarch(vec3 ray_origin, vec3 ray_dir)
{
	float dist_from_origin = 0.0;
	float current_dist = 0.0;

	for (int i = 0; i < MAX_STEPS; i++)
	{
		vec3 raycast_position = ray_origin + ray_dir * dist_from_origin;

		current_dist = sdf3D_get_scene(raycast_position);
		dist_from_origin += current_dist;

		// If we hit a surface or didn't hit anything, break out the loop
		if (current_dist < SURFACE_DISTANCE || dist_from_origin > MAX_DISTANCE)
			break;
	}

	return dist_from_origin;
}

#define ZERO int(min(TIME, 0.0)) // Non-constant zero to prevent inlining

// From Inigo Quilez on normals
// https://iquilezles.org/articles/normalsSDF/
// Licensed under the MIT License.
vec3 sdf3D_get_normal(vec3 raycast_position)
{
	const float NORMAL_EPSILON = 0.01;
	vec3 normal = vec3(0.0);

	for (int i = ZERO; i < 4; i++)
	{
		vec3 e = 0.5773 * (2.0 * vec3(float(((i + 3) >> 1) & 1), float((i >> 1) & 1), float(i & 1))-1.0);
		normal += e * sdf3D_get_scene(raycast_position + e * NORMAL_EPSILON);
	}

	return normalize(normal);
}

// https://discussions.unity.com/t/sdf-raymarching-correct-depth-testing-w-normal-non-sdf-rendered-gameobjects/935578/3
// https://discussions.unity.com/t/raymarcher-with-depth-buffer/787930
float sdf3D_get_max_depth(vec3 ray, vec3 viewspace_forward_dir, vec2 screen_uv, mat4 inv_proj_matrix)
{
	float depth = texture(depth_texture, screen_uv).x;

	// Normalized device coordinates
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(screen_uv, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(screen_uv * 2.0 - 1.0, depth);
	#endif

	vec4 view = inv_proj_matrix * vec4(ndc, 1.0);
	view.xyz /= view.w;

	float linear_depth = length(view.xyz);

	ray /= dot(ray, viewspace_forward_dir);

	return length(linear_depth * ray);
}

// Vertex/fragment: Portions taken from Digvijaysinh Gohil's video on raymarching
// https://www.youtube.com/watch?v=68G3V5Yr8FY

varying mat4 model_view_matrix;
varying vec3 local_space_vertex;

void vertex()
{
	model_view_matrix = MODELVIEW_MATRIX;
	local_space_vertex = VERTEX;
}

void fragment()
{
	vec3 ray_origin = (inverse(MODEL_MATRIX) * vec4(CAMERA_POSITION_WORLD, 1.0)).xyz;
	vec3 ray_dir = normalize(local_space_vertex - ray_origin);

	float dist = sdf3D_raymarch(ray_origin, ray_dir);

	if (dist > MAX_DISTANCE)
		discard;

	vec3 raycast_position = ray_origin + ray_dir * dist;
	vec3 normal = sdf3D_get_normal(raycast_position);

	NORMAL = normal;

	vec4 sdf_ndc = PROJECTION_MATRIX * VIEW_MATRIX * vec4(raycast_position, 1.0);

	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	DEPTH = (sdf_ndc.z / sdf_ndc.w) * 0.5 + 0.5;
	#else
	DEPTH = (sdf_ndc.z / sdf_ndc.w);
	#endif

	ALBEDO = vec3(0.2);
	//LIGHT_VERTEX = sdf_ndc.xyz;
	//LIGHT_VERTEX = (PROJECTION_MATRIX * VIEW_MATRIX * MODEL_MATRIX * vec4(raycast_position, 1.0)).xyz;
}

//void light()
//{
	//DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
//}
