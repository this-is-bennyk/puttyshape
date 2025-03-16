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

// All distance functions from Inigo Quilez on Distance Functions
// https://iquilezles.org/articles/distfunctions/
// Licensed under the MIT License.

const int SDF3D_SWIZZLE_YX = 0;
const int SDF3D_SWIZZLE_ZX =  SDF3D_SWIZZLE_YX + 1;
const int SDF3D_SWIZZLE_ZY = SDF3D_SWIZZLE_ZX + 1;
const int SDF3D_SWIZZLE_XZY = SDF3D_SWIZZLE_ZY + 1;
const int SDF3D_SWIZZLE_YXZ = SDF3D_SWIZZLE_XZY + 1;
const int SDF3D_SWIZZLE_YZX = SDF3D_SWIZZLE_YXZ + 1;
const int SDF3D_SWIZZLE_ZXY = SDF3D_SWIZZLE_YZX + 1;
const int SDF3D_SWIZZLE_ZYX = SDF3D_SWIZZLE_ZXY + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_X = SDF3D_SWIZZLE_ZYX + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_Y = SDF3D_SWIZZLE_SYMMETRICAL_X + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_Z = SDF3D_SWIZZLE_SYMMETRICAL_Y + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_XY = SDF3D_SWIZZLE_SYMMETRICAL_Z + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_YX = SDF3D_SWIZZLE_SYMMETRICAL_XY + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_XZ = SDF3D_SWIZZLE_SYMMETRICAL_YX + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_ZX = SDF3D_SWIZZLE_SYMMETRICAL_XZ + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_YZ = SDF3D_SWIZZLE_SYMMETRICAL_ZX + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_ZY = SDF3D_SWIZZLE_SYMMETRICAL_YZ + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_XYZ = SDF3D_SWIZZLE_SYMMETRICAL_ZY + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_XZY = SDF3D_SWIZZLE_SYMMETRICAL_XYZ + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_YXZ = SDF3D_SWIZZLE_SYMMETRICAL_XZY + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_YZX = SDF3D_SWIZZLE_SYMMETRICAL_YXZ + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_ZXY = SDF3D_SWIZZLE_SYMMETRICAL_YZX + 1;
const int SDF3D_SWIZZLE_SYMMETRICAL_ZYX = SDF3D_SWIZZLE_SYMMETRICAL_ZXY + 1;

vec3 sdf3D_swizzle(vec3 raycast_position, int modification)
{
	switch (modification)
	{
		case SDF3D_SWIZZLE_YX:
			raycast_position.xy = raycast_position.yx;
			break;
		case SDF3D_SWIZZLE_ZX:
			raycast_position.xz = raycast_position.zx;
			break;
		case SDF3D_SWIZZLE_ZY:
			raycast_position.yz = raycast_position.zy;
			break;
		case SDF3D_SWIZZLE_XZY:
			raycast_position.xyz = raycast_position.xzy;
			break;
		case SDF3D_SWIZZLE_YXZ:
			raycast_position.xyz = raycast_position.yxz;
			break;
		case SDF3D_SWIZZLE_YZX:
			raycast_position.xyz = raycast_position.yzx;
			break;
		case SDF3D_SWIZZLE_ZXY:
			raycast_position.xyz = raycast_position.zxy;
			break;
		case SDF3D_SWIZZLE_ZYX:
			raycast_position.xyz = raycast_position.zyx;
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_X:
			raycast_position.x = abs(raycast_position.x);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_Y:
			raycast_position.y = abs(raycast_position.y);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_Z:
			raycast_position.z = abs(raycast_position.z);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_XY:
			raycast_position.xy = abs(raycast_position.xy);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_YX:
			raycast_position.xy = abs(raycast_position.yx);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_XZ:
			raycast_position.xz = abs(raycast_position.xz);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_ZX:
			raycast_position.xz = abs(raycast_position.zx);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_YZ:
			raycast_position.yz = abs(raycast_position.yz);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_ZY:
			raycast_position.yz = abs(raycast_position.zy);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_XYZ:
			raycast_position.xyz = abs(raycast_position.xyz);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_XZY:
			raycast_position.xyz = abs(raycast_position.xzy);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_YXZ:
			raycast_position.xyz = abs(raycast_position.yxz);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_YZX:
			raycast_position.xyz = abs(raycast_position.yzx);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_ZXY:
			raycast_position.xyz = abs(raycast_position.zxy);
			break;
		case SDF3D_SWIZZLE_SYMMETRICAL_ZYX:
			raycast_position.xyz = abs(raycast_position.zyx);
			break;
	}

	return raycast_position;
}

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

float sdf3D_generate(vec3 raycast_position, int shape, mat4 transform, float scale, float prev_sdf, vec4 args1, vec4 args2)
{
	const float INFINITY = 3.402823466e38;
	float sdf = INFINITY;

	raycast_position = (transform * vec4(raycast_position, 1.0)).xyz / scale;

	switch (shape)
	{
		case SDF3D_SHAPE_SPHERE:
			 // Radius

			sdf = length(raycast_position) - args1.x;
			break;

		case SDF3D_SHAPE_BOX:
			 // Bounds

			vec3 q = abs(raycast_position) - vec3(args1.x, args1.y, args1.z);
			sdf = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
			break;

		case SDF3D_SHAPE_ROUNDED_BOX:
			 // Bounds
			 // Rounding radius

			vec3 q = abs(raycast_position) - vec3(args1.x, args1.y, args1.z) + args1.w;
			sdf = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - args1.w;
			break;

		case SDF3D_SHAPE_BOX_FRAME:
			 // Bounds
			 // Edge width

			raycast_position = abs(raycast_position) - vec3(args1.x, args1.y, args1.z);
			vec3 q = abs(raycast_position + args1.w) - args1.w;
			sdf = min(min(
			length(max(vec3(raycast_position.x, q.y, q.z),0.0)) + min(max(raycast_position.x, max(q.y, q.z)), 0.0),
			length(max(vec3(q.x, raycast_position.y, q.z),0.0)) + min(max(q.x, max(raycast_position.y, q.z)), 0.0)),
			length(max(vec3(q.x, q.y, raycast_position.z),0.0)) + min(max(q.x, max(q.y, raycast_position.z)), 0.0));
			break;

		case SDF3D_SHAPE_TORUS:
			 // Radius
			 // Thickness

			vec2 q = vec2(length(raycast_position.xz) - args1.x, raycast_position.y);
			sdf = length(q) - args1.y;
			break;

		case SDF3D_SHAPE_CAPPED_TORUS:
			 // Angle
			 // Radius
			 // Thickness

			vec2 sin_cosine = vec2(sin(args1.x), cos(args1.x));
			raycast_position.x = abs(raycast_position.x);
			float k = (sin_cosine.y * raycast_position.x > sin_cosine.x * raycast_position.y) ? dot(raycast_position.xy, sin_cosine) : length(raycast_position.xy);
			sdf = sqrt(dot(raycast_position, raycast_position) + args1.y * args1.y - 2.0 * args1.y * k) - args1.z;
			break;

		case SDF3D_SHAPE_LINK:
			 // Length
			 // Radius
			 // Thickness

			vec3 q = vec3(raycast_position.x, max(abs(raycast_position.y) - args1.x, 0.0), raycast_position.z);
			sdf = length(vec2(length(q.xy) - args1.y, q.z)) - args1.z;
			break;

		case SDF3D_SHAPE_INFINITE_CYLINDER:
			 // Position Offset
			 // Radius

			sdf = length(raycast_position.xz - vec2(args1.x, args1.y)) - args1.z;
			break;

		case SDF3D_SHAPE_CONE:
			 // Angle
			 // Height

			vec2 sin_cosine = vec2(sin(args1.x), cos(args1.x));
			vec2 q = args1.y * vec2(sin_cosine.x / sin_cosine.y, -1.0);

			vec2 w = vec2(length(raycast_position.xz), raycast_position.y);
			vec2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
			vec2 b = w - q * vec2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
			float k = sign(q.y);
			float d = min(dot(a, a), dot(b, b));
			float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
			sdf = sqrt(d) * sign(s);
			break;

		case SDF3D_SHAPE_INFINITE_CONE:
			 // Angle

			vec2 sin_cosine = vec2(sin(args1.x), cos(args1.x));

			vec2 q = vec2(length(raycast_position.xz), -raycast_position.y);
			float d = length(q - sin_cosine * max(dot(q, sin_cosine), 0.0));
			sdf = d * ((q.x * sin_cosine.y - q.y * sin_cosine.x < 0.0) ? -1.0 : 1.0);
			break;

		case SDF3D_SHAPE_PLANE:
			 // Normal
			 // Height

			sdf = dot(raycast_position, vec3(args1.x, args1.y, args1.z)) + args1.w;
			break;

		case SDF3D_SHAPE_HEXAGONAL_PRISM:
			 // Radius
			 // Length

			const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
			raycast_position = abs(raycast_position);
			raycast_position.xy -= 2.0 * min(dot(k.xy, raycast_position.xy), 0.0) * k.xy;
			vec2 d = vec2(
				length(raycast_position.xy - vec2(clamp(raycast_position.x, -k.z * args1.x, k.z * args1.x), args1.x)) * sign(raycast_position.y - args1.x),
				raycast_position.z - args1.y);
			sdf = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
			break;

		case SDF3D_SHAPE_TRIANGULAR_PRISM:
			 // Radius
			 // Length

			const float k = sqrt(3.0);

			args1.x *= 0.5 * k;
			raycast_position.xy /= args1.x;
			raycast_position.x = abs(raycast_position.x) - 1.0;
			raycast_position.y = raycast_position.y + 1.0 / k;

			if (raycast_position.x + k * raycast_position.y > 0.0)
				raycast_position.xy = vec2(raycast_position.x - k * raycast_position.y, -k * raycast_position.x - raycast_position.y) / 2.0;

			raycast_position.x -= clamp(raycast_position.x, -2.0, 0.0);

			float d1 = length(raycast_position.xy) * sign(-raycast_position.y) * args1.x;
			float d2 = abs(raycast_position.z) - args1.y;

			sdf = length(max(vec2(d1, d2), 0.0)) + min(max(d1, d2), 0.0);
			break;

		case SDF3D_SHAPE_VERTICAL_CAPSULE:
			 // Height
			 // Radius

			raycast_position.y -= clamp(raycast_position.y, 0.0, args1.x);
			sdf = length(raycast_position) - args1.y;
			break;

		case SDF3D_SHAPE_ARBITRARY_CAPSULE:
			 // Start
			 // End
			 // Radius

			vec3 pa = raycast_position - vec3(args1.x, args1.y, args1.z), ba = vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z);
			float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
			sdf = length(pa - ba * h) - args2.z;
			break;

		case SDF3D_SHAPE_VERTICAL_CAPPED_CYLINDER:
			 // Height
			 // Radius

			vec2 d = abs(vec2(length(raycast_position.xz), raycast_position.y)) - vec2(args1.y, args1.x);
			sdf = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
			break;

		case SDF3D_SHAPE_ARBITRARY_CAPPED_CYLINDER:
			 // Start
			 // End
			 // Radius

			vec3  ba = vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z);
			vec3  pa = raycast_position - vec3(args1.x, args1.y, args1.z);
			float baba = dot(ba, ba);
			float paba = dot(pa, ba);
			float x = length(pa * baba - ba * paba) - args2.z * baba;
			float y = abs(paba - baba * 0.5) - baba * 0.5;
			float x2 = x * x;
			float y2 = y * y * baba;
			float d = (max(x, y) < 0.0) ? -min(x2, y2) : (((x > 0.0) ? x2 : 0.0) + ((y > 0.0) ? y2 : 0.0));
			sdf = sign(d) * sqrt(abs(d)) / baba;
			break;

		case SDF3D_SHAPE_ROUNDED_CYLINDER:
			 // Cylinder Radius
			 // Rounding Radius
			 // Height

			vec2 d = vec2(length(raycast_position.xz) - 2.0 * args1.x + args1.y, abs(raycast_position.y) - args1.z);
			sdf = min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - args1.y;
			break;

		case SDF3D_SHAPE_VERTICAL_CAPPED_CONE:
			 // Height
			 // Bottom Radius
			 // Top Radius

			vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
			vec2 k1 = vec2(args1.z, args1.x);
			vec2 k2 = vec2(args1.z - args1.y, 2.0 * args1.x);
			vec2 ca = vec2(q.x - min(q.x, (q.y < 0.0) ? args1.y : args1.z), abs(q.y) - args1.x);
			vec2 cb = q - k1 + k2 * clamp(dot(k1-q,k2) / (dot(k2, k2)), 0.0, 1.0);
			float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
			sdf = s * sqrt(min(dot(ca, ca), dot(cb, cb)));
			break;

		case SDF3D_SHAPE_ARBITRARY_CAPPED_CONE:
			 // Start
			 // End
			 // Bottom Radius
			 // Top Radius

			float rba  = args2.w - args2.z;
			float baba = dot(vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z), vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z));
			float papa = dot(raycast_position - vec3(args1.x, args1.y, args1.z), raycast_position - vec3(args1.x, args1.y, args1.z));
			float paba = dot(raycast_position - vec3(args1.x, args1.y, args1.z), vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z)) / baba;
			float x = sqrt(papa - paba * paba * baba);
			float cax = max(0.0, x - ((paba < 0.5) ? args2.z : args2.w));
			float cay = abs(paba-0.5)-0.5;
			float k = rba*rba + baba;
			float f = clamp((rba * (x - args2.z) + paba * baba) / k, 0.0, 1.0);
			float cbx = x - args2.z - f * rba;
			float cby = paba - f;
			float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
			sdf = s * sqrt(min(cax*cax + cay * cay * baba, cbx * cbx + cby * cby * baba));
			break;

		case SDF3D_SHAPE_SOLID_ANGLE:
			 // Angle
			 // Radius

			vec2 sin_cosine = vec2(sin(args1.x), cos(args1.x));
			vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
			float l = length(q) - args1.y;
			float m = length(q - sin_cosine * clamp(dot(q, sin_cosine), 0.0, args1.y));
			sdf = max(l, m * sign(sin_cosine.y * q.x - sin_cosine.x * q.y));
			break;

		case SDF3D_SHAPE_CUT_SPHERE:
			 // Radius
			 // Cut Depth

			// sampling independent computations (only depend on shape)
			float w = sqrt(args1.x * args1.x - args1.y * args1.y);

			// sampling dependant computations
			vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
			float s = max((args1.y - args1.x) * q.x * q.x + w * w * (args1.y + args1.x - 2.0 * q.y), args1.y * q.x - w * q.y);
			sdf = (s < 0.0) ? length(q) - args1.x : (q.x < w) ? args1.y - q.y : length(q - vec2(w, args1.y));
			break;

		case SDF3D_SHAPE_CUT_HOLLOW_SPHERE:
			 // Radius
			 // Cut Depth
			 // Thickness

			// sampling independent computations (only depend on shape)
			float w = sqrt(args1.x * args1.x - args1.y * args1.y);

			// sampling dependant computations
			vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
			sdf = ((args1.y * q.x < w * q.y) ? length(q - vec2(w, args1.y)) : abs(length(q) - args1.x)) - args1.z;
			break;

		case SDF3D_SHAPE_VERTICAL_ROUND_CONE:
			 // Height
			 // Bottom Radius
			 // Top Radius

			// sampling independent computations (only depend on shape)
			float b = (args1.y - args1.z) / args1.x;
			float a = sqrt(1.0 - b * b);

			// sampling dependant computations
			vec2 q = vec2(length(raycast_position.xz), raycast_position.y);
			float k = dot(q,vec2(-b, a));

			if (k < 0.0)
				sdf = length(q) - args1.y;
			else if (k > a * args1.x)
				sdf = length(q - vec2(0.0, args1.x)) - args1.z;
			else
				sdf = dot(q, vec2(a, b)) - args1.y;

			break;

		case SDF3D_SHAPE_ARBITRARY_ROUND_CONE:
			 // Start
			 // End
			 // Bottom Radius
			 // Top Radius

			// sampling independent computations (only depend on shape)
			vec3  ba = vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z);
			float l2 = dot(ba,ba);
			float rr = args2.z - args2.w;
			float a2 = l2 - rr * rr;
			float il2 = 1.0 / l2;

			// sampling dependant computations
			vec3 pa = raycast_position - vec3(args1.x, args1.y, args1.z);
			float y = dot(pa, ba);
			float z = y - l2;
			float x2 = dot(pa * l2 - ba * y, pa * l2 - ba * y);
			float y2 = y * y * l2;
			float z2 = z * z * l2;

			// single square root!
			float k = sign(rr) * rr * rr * x2;

			if (sign(z) * a2 * z2 > k)
				sdf = sqrt(x2 + z2) * il2 - args2.w;
			else if (sign(y) * a2 * y2 < k)
				sdf = sqrt(x2 + y2) * il2 - args2.z;
			else
				sdf = (sqrt(x2 * a2 * il2) + y * rr) * il2 - args2.z;

			break;

		case SDF3D_SHAPE_ELLIPSOID_BOUND:
			 // Radii

			float k0 = length(raycast_position / vec3(args1.x, args1.y, args1.z));
			float k1 = length(raycast_position / (vec3(args1.x, args1.y, args1.z) * vec3(args1.x, args1.y, args1.z)));
			sdf = k0 * (k0 - 1.0) / k1;
			break;

		case SDF3D_SHAPE_VERTICAL_VESICA_SEGMENT:
			 // Height
			 // Weight

			// shape constants
			args1.x *= 0.5;
			args1.y *= 0.5;
			float d = 0.5 * (args1.x * args1.x - args1.y * args1.y) / args1.y;

			// project to 2D
			vec2 q = vec2(length(raycast_position.xz), abs(raycast_position.y - args1.x));

			// feature selection (vertex or body)
			vec3 t = (args1.x * q.x < d * (q.y - args1.x)) ? vec3(0.0, args1.x, 0.0) : vec3(-d, 0.0, d + args1.y);

			// distance
			sdf = length(q - t.xy) - t.z;
			break;

		case SDF3D_SHAPE_ARBITRARY_VESICA_SEGMENT:
			 // Start
			 // End
			 // Weight

			// orient and project to 2D
			vec3  c = (vec3(args1.x, args1.y, args1.z) + vec3(args1.w, args2.x, args2.y)) * 0.5;
			float h = length(vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z));
			vec3  v = (vec3(args1.w, args2.x, args2.y) - vec3(args1.x, args1.y, args1.z)) / h;
			float y = dot(raycast_position - c, v);
			vec2  q = vec2(length(raycast_position - c - y * v), abs(y));

			// shape constants
			h *= 0.5;
			args2.z *= 0.5;
			float d = 0.5 * (h * h - args2.z * args2.z) / args2.z;

			// feature selection (vertex or body)
			vec3 t = (h * q.x < d * (q.y - h)) ? vec3(0.0, h, 0.0) : vec3(-d, 0.0, d + args2.z);

			// distance
			sdf = length(q - t.xy) - t.z;
			break;

		case SDF3D_SHAPE_RHOMBUS:
			 // Horizontal Length
			 // Vertical Length
			 // Height
			 // Radius

			raycast_position = abs(raycast_position);
			vec2 b = vec2(args1.y, args1.x);
			vec2 b_offset = b - 2.0 * raycast_position.xz;
			float ndot = b.x * b_offset.x - b.y * b_offset.y;
			float f = clamp(ndot / dot(b, b), -1.0, 1.0);
			vec2 q = vec2(length(raycast_position.xz - 0.5 * b * vec2(1.0 - f, 1.0 + f)) * sign(raycast_position.x * b.y + raycast_position.z * b.x - b.x * b.y) - args1.w, raycast_position.y - args1.z);
			sdf = min(max(q.x, q.y), 0.0) + length(max(q, 0.0));
			break;

		case SDF3D_SHAPE_OCTAHEDRON:
			 // Radius

			raycast_position = abs(raycast_position);

			float m = raycast_position.x + raycast_position.y + raycast_position.z - args1.x;
			vec3 q;

			if (3.0 * raycast_position.x < m)
				q = raycast_position.xyz;
			else if (3.0 * raycast_position.y < m)
				q = raycast_position.yzx;
			else if (3.0 * raycast_position.z < m)
				q = raycast_position.zxy;
			else
				sdf = m * 0.57735027;

			if ((3.0 * raycast_position.x < m) || (3.0 * raycast_position.y < m) || 3.0 * raycast_position.z < m)
			{
				float k = clamp(0.5 * (q.z - q.y + args1.x), 0.0, args1.x);
				sdf = length(vec3(q.x, q.y - args1.x + k, q.z - k));
			}

			break;

		case SDF3D_SHAPE_PYRAMID:
			 // Height

			float m2 = args1.x * args1.x + 0.25;

			raycast_position.xz = abs(raycast_position.xz);
			raycast_position.xz = (raycast_position.z > raycast_position.x) ? raycast_position.zx : raycast_position.xz;
			raycast_position.xz -= 0.5;

			vec3 q = vec3(raycast_position.z, args1.x * raycast_position.y - 0.5 * raycast_position.x, args1.x * raycast_position.x + 0.5 * raycast_position.y);

			float s = max(-q.x,0.0);
			float t = clamp((q.y - 0.5 * raycast_position.z) / (m2 + 0.25), 0.0, 1.0);

			float a = m2 * (q.x + s) *(q.x + s) + q.y * q.y;
			float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);

			float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);

			sdf = sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -raycast_position.y));
			break;

		default:
			break;
	}

	return sdf * scale;
}

const int SDF3D_MODIFIER_INFINITE_DOMAIN_REPETITION = 0;
const int SDF3D_MODIFIER_FINITE_DOMAIN_REPETITION = SDF3D_MODIFIER_INFINITE_DOMAIN_REPETITION + 1;
const int SDF3D_MODIFIER_ELONGATION = SDF3D_MODIFIER_FINITE_DOMAIN_REPETITION + 1;
const int SDF3D_MODIFIER_ROUND = SDF3D_MODIFIER_ELONGATION + 1;
const int SDF3D_MODIFIER_ONION = SDF3D_MODIFIER_ROUND + 1;
const int SDF3D_MODIFIER_DISPLACE = SDF3D_MODIFIER_ONION + 1;
const int SDF3D_MODIFIER_TWIST = SDF3D_MODIFIER_DISPLACE + 1;
const int SDF3D_MODIFIER_BEND = SDF3D_MODIFIER_TWIST + 1;

float sdf3D_modify(int modifier, vec3 raycast_position, int shape, mat4 transform, float scale, float prev_sdf, vec4 shape_args1, vec4 shape_args2)
{
	switch (modifier)
	{
		case SDF3D_MODIFIER_INFINITE_DOMAIN_REPETITION:

			break;

		case SDF3D_MODIFIER_FINITE_DOMAIN_REPETITION:

			break;

		case SDF3D_MODIFIER_ELONGATION:

			break;

		case SDF3D_MODIFIER_ROUND:

			break;

		case SDF3D_MODIFIER_ONION:

			break;

		case SDF3D_MODIFIER_DISPLACE:

			break;

		case SDF3D_MODIFIER_TWIST:

			break;

		case SDF3D_MODIFIER_BEND:

			break;

		default:
			break;
	}
	return 0.0;
}

const int SDF3D_COMBINER_UNION = 0;
const int SDF3D_COMBINER_XOR = SDF3D_COMBINER_UNION + 1;
const int SDF3D_COMBINER_SUBTRACTION_BOUND = SDF3D_COMBINER_XOR + 1;
const int SDF3D_COMBINER_INTERSECTION_BOUND = SDF3D_COMBINER_SUBTRACTION_BOUND + 1;
const int SDF3D_COMBINER_SMOOTH_UNION_BOUND = SDF3D_COMBINER_INTERSECTION_BOUND + 1;
const int SDF3D_COMBINER_SMOOTH_SUBTRACTION_BOUND = SDF3D_COMBINER_SMOOTH_UNION_BOUND + 1;
const int SDF3D_COMBINER_SMOOTH_INTERSECTION_BOUND = SDF3D_COMBINER_SMOOTH_SUBTRACTION_BOUND + 1;

float sdf3D_combine(float sdf1, float sdf2, int combination, float smoothing_radius)
{
	float sdf = sdf1;

	switch (combination)
	{
		case SDF3D_COMBINER_XOR:
			sdf = max(min(sdf1, sdf2), -max(sdf1, sdf2));
			break;

		case SDF3D_COMBINER_SUBTRACTION_BOUND:
			sdf = max(-sdf1, sdf2);
			break;

		case SDF3D_COMBINER_INTERSECTION_BOUND:
			sdf = max(sdf1, sdf2);
			break;

		case SDF3D_COMBINER_SMOOTH_UNION_BOUND:
			float h = clamp(0.5 + 0.5 * (sdf2 - sdf1) / smoothing_radius, 0.0, 1.0);
			sdf = mix(sdf2, sdf1, h) - smoothing_radius * h * (1.0 - h);
			break;

		case SDF3D_COMBINER_SMOOTH_SUBTRACTION_BOUND:
			float h = clamp(0.5 - 0.5 * (sdf2 + sdf1) / smoothing_radius, 0.0, 1.0);
			sdf = mix(sdf2, -sdf1, h) + smoothing_radius * h * (1.0 - h);
			break;

		case SDF3D_COMBINER_SMOOTH_INTERSECTION_BOUND:
			float h = clamp(0.5 - 0.5 * (sdf2 - sdf1) / smoothing_radius, 0.0, 1.0);
			sdf = mix(sdf2, sdf1, h) + smoothing_radius * h * (1.0 - h);
			break;

		default: // Union
			sdf = min(sdf1, sdf2);
			break;
	}

	return sdf;
}
