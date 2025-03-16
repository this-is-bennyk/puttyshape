shader_type spatial;
render_mode world_vertex_coords;

uniform sampler2D diffuse_map;
uniform sampler2DArray a;
uniform float texture_scale = 1.0;
uniform float triplanar_blend_sharpness = 0.0;
uniform bool transparent = false;

varying vec3 world_space_vertex;
varying vec3 world_space_normal;

void vertex()
{
	world_space_vertex = VERTEX;
	world_space_normal = NORMAL;
}

void fragment()
{
	float sharpness = abs(triplanar_blend_sharpness);

	vec2 y_uv = world_space_vertex.xz;
	vec2 x_uv = world_space_vertex.zy;
	vec2 z_uv = world_space_vertex.xy;

	vec4 y_diff = texture(diffuse_map, y_uv);
	vec4 x_diff = texture(diffuse_map, x_uv);
	vec4 z_diff = texture(diffuse_map, z_uv);

	vec3 blend_weights = pow(abs(world_space_normal), vec3(sharpness));

	blend_weights /= blend_weights.x + blend_weights.y + blend_weights.z;

	vec4 result = x_diff * blend_weights.x + y_diff * blend_weights.y + z_diff * blend_weights.z;

	ALBEDO = result.xyz;

	if (transparent)
		ALPHA = result.a;
}
