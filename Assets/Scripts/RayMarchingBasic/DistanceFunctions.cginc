// FUNCTIONS
float3 dot2two(float2 vec)
{
	return dot(vec, vec);
}

float dot2three(float3 vec)
{
	return dot(vec, vec);
}

float ndot(float2 a, float2 b) 
{
	return a.x * b.x - a.y * b.y; 
}

float fract(float x) {
	return x - floor(x);
}

// POSITIONING
// Mod Position Axis
float pMod1(inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p + halfsize) / size);
	p = fmod(p + halfsize, size) - halfsize;
	p = fmod(-p + halfsize, size) - halfsize;
	return c;
}

float pMod(float p, float size)
{
	float halfsize = size * 0.5;
	p = fmod(p + halfsize, size) - halfsize;
	p = fmod(-p + halfsize, size) - halfsize;
	return p;
}

// Twist the point across the x axis.
// k: Twist factor.
float3 opTwistX(float3 p, float k)
{
	float c = cos(k * p.x);
	float s = sin(k * p.x);
	float3x3 m = float3x3(1, 0, 0, 0, c, -s, 0, s, c);
	float3 q = mul(m, p);
	return q;
}

// Twist the point across the y axis.
// k: Twist factor.
float3 opTwistY(float3 p, float k)
{
	float c = cos(k * p.y);
	float s = sin(k * p.y);
	float3x3 m = float3x3(c, 0, s, 0, 1, 0, -s, 0, c);
	float3 q = mul(m, p);
	return q;
}

// Twist the point across the z axis.
// k: Twist factor.
float3 opTwistZ(float3 p, float k)
{
	float c = cos(k * p.z);
	float s = sin(k * p.z);
	float3x3 m = float3x3(c, -s, 0, s, c, 0, 0, 0, 1);
	float3 q = mul(m, p);
	return q;
}

// SHAPES

// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Round Box
float sdRoundBox(float3 p, float3 b, float r)
{
	float3 q = abs(p) - b;
	return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

// Box Frame
float sdBoxFrame(float3 p, float3 b, float e)
{
	p = abs(p) - b;
	float3 q = abs(p + e) - e;
	return min(min(
	length(max(float3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0),
	length(max(float3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)),
	length(max(float3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
}

// InfBox
// b: size of box in x/y/z
float sd2DBox(in float2 p, in float2 b)
{
	float2 d = abs(p) - b;
	return length(max(d, float2(0, 0))) + min(max(d.x, d.y), 0.0);
}

// Cross
// s: size of cross
float sdCross(in float3 p, float b)
{
	float da = sd2DBox(p.xy, float2(b, b));
	float db = sd2DBox(p.yz, float2(b, b));
	float dc = sd2DBox(p.zx, float2(b, b));
	return min(da, min(db, dc));
}

// Torus
float sdTorus(float3 p, float2 t)
{
	float2 q = float2(length(p.xz) - t.x, p.y);
	return length(q) - t.y;
}

// Capped Torus
float sdCappedTorus(in float3 p, in float2 sc, in float ra, in float rb)
{
	p.x = abs(p.x);
	float k = (sc.y * p.x > sc.x * p.y) ? dot(p.xy, sc) : length(p.xy);
	return sqrt(dot(p, p) + ra * ra - 2.0 * ra * k) - rb;
}

// Link
float sdLink(float3 p, float le, float r1, float r2)
{
	float3 q = float3(p.x, max(abs(p.y) - le, 0.0), p.z);
	return length(float2(length(q.xy) - r1, q.z)) - r2;
}

// Infinite Cylinder
float sdCylinder(float3 p, float3 c)
{
	return length(p.xz - c.xy) - c.z;
}

// Cone
float sdCone(in float3 p, in float2 c, float h)
{
	// c is the sin/cos of the angle, h is height
	// Alternatively pass q instead of (c,h),
	// which is the point at the base in 2D
	float2 q = h * float2(c.x / c.y, -1.0);

	float2 w = float2(length(p.xz), p.y);
	float2 a = w - q * clamp(dot(w, q) / dot(q, q), 0.0, 1.0);
	float2 b = w - q * float2(clamp(w.x / q.x, 0.0, 1.0), 1.0);
	float k = sign(q.y);
	float d = min(dot(a, a), dot(b, b));
	float s = max(k * (w.x * q.y - w.y * q.x), k * (w.y - q.y));
	return sqrt(d) * sign(s);
}

// Plane
float sdPlane(float3 p, float3 n, float h)
{
	// n must be normalized
	return dot(p, n) + h;
}

// Hexagonal Prism
float sdHexPrism(float3 p, float2 h)
{
	const float3 k = float3(-0.8660254, 0.5, 0.57735);
	p = abs(p);
	p.xy -= 2.0 * min(dot(k.xy, p.xy), 0.0) * k.xy;
	float2 d = float2(
	length(p.xy - float2(clamp(p.x, -k.z * h.x, k.z * h.x), h.x)) * sign(p.y - h.x),
	p.z - h.y);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Triangular Prism
float sdTriPrism(float3 p, float2 h)
{
	float3 q = abs(p);
	return max(q.z - h.y, max(q.x * 0.866025 + p.y * 0.5, -p.y) - h.x * 0.5);
}

// Capsule // Line
float sdCapsule(float3 p, float3 a, float3 b, float r)
{
	float3 pa = p - a, ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

// Capped Cylinder
float sdCappedCylinder(float3 p, float h, float r)
{
	float2 d = abs(float2(length(p.xz), p.y)) - float2(h, r);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

// Rounded Cylinder
float sdRoundedCylinder(float3 p, float ra, float rb, float h)
{
	float2 d = float2(length(p.xz) - 2.0 * ra + rb, abs(p.y) - h);
	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

// Capped Cone
float sdCappedCone(float3 p, float h, float r1, float r2)
{
	float2 q = float2(length(p.xz), p.y);
	float2 k1 = float2(r2, h);
	float2 k2 = float2(r2 - r1, 2.0 * h);
	float2 ca = float2(q.x - min(q.x, (q.y < 0.0) ? r1 : r2), abs(q.y) - h);
	float2 cb = q - k1 + k2 * clamp(dot(k1 - q, k2) / dot2two(k2), 0.0, 1.0);
	float s = (cb.x < 0.0 && ca.y < 0.0) ? -1.0 : 1.0;
	return s * sqrt(min(dot2two(ca), dot2two(cb)));
}

// Solid Angle
float sdSolidAngle(float3 p, float2 c, float ra)
{
	// c is the sin/cos of the angle
	float2 q = float2(length(p.xz), p.y);
	float l = length(q) - ra;
	float m = length(q - c * clamp(dot(q, c), 0.0, ra));
	return max(l, m * sign(c.y * q.x - c.x * q.y));
}

// Round Cone
float sdRoundCone(float3 p, float r1, float r2, float h)
{
	float2 q = float2(length(p.xz), p.y);

	float b = (r1 - r2) / h;
	float a = sqrt(1.0 - b * b);
	float k = dot(q, float2(-b, a));

	if (k < 0.0) return length(q) - r1;
	if (k > a * h) return length(q - float2(0.0, h)) - r2;

	return dot(q, float2(a, b)) - r1;
}

// Ellipsoid
float sdEllipsoid(float3 p, float3 r)
{
	float k0 = length(p / r);
	float k1 = length(p / (r * r));
	return k0 * (k0 - 1.0) / k1;
}

// Rhombus
float sdRhombus(float3 p, float la, float lb, float h, float ra)
{
	p = abs(p);
	float2 b = float2(la, lb);
	float f = clamp((ndot(b, b - 2.0 * p.xz)) / dot(b, b), -1.0, 1.0);
	float2 q = float2(length(p.xz - 0.5 * b * float2(1.0 - f, 1.0 + f)) * sign(p.x * b.y + p.z * b.x - b.x * b.y) - ra, p.y - h);
	return min(max(q.x, q.y), 0.0) + length(max(q, 0.0));
}

// Octahedron
float sdOctahedron(float3 p, float s)
{
	p = abs(p);
	float m = p.x + p.y + p.z - s;
	float3 q;
	if (3.0 * p.x < m) q = p.xyz;
	else if (3.0 * p.y < m) q = p.yzx;
	else if (3.0 * p.z < m) q = p.zxy;
	else return m * 0.57735027;

	float k = clamp(0.5 * (q.z - q.y + s), 0.0, s);
	return length(float3(q.x, q.y - s + k, q.z - k));
}

// Pyramid
float sdPyramid(float3 p, float h)
{
	float m2 = h * h + 0.25;

	p.xz = abs(p.xz);
	p.xz = (p.z > p.x) ? p.zx : p.xz;
	p.xz -= 0.5;

	float3 q = float3(p.z, h * p.y - 0.5 * p.x, h * p.x + 0.5 * p.y);

	float s = max(-q.x, 0.0);
	float t = clamp((q.y - 0.5 * p.z) / (m2 + 0.25), 0.0, 1.0);

	float a = m2 * (q.x + s) * (q.x + s) + q.y * q.y;
	float b = m2 * (q.x + 0.5 * t) * (q.x + 0.5 * t) + (q.y - m2 * t) * (q.y - m2 * t);

	float d2 = min(q.y, -q.x * m2 - q.y * 0.5) > 0.0 ? 0.0 : min(a, b);

	return sqrt((d2 + q.z * q.z) / m2) * sign(max(q.z, -p.y));
}

// Triangle
float udTriangle(float3 p, float3 a, float3 b, float3 c)
{
	float3 ba = b - a; float3 pa = p - a;
	float3 cb = c - b; float3 pb = p - b;
	float3 ac = a - c; float3 pc = p - c;
	float3 nor = cross(ba, ac);

	return sqrt(
	(sign(dot(cross(ba, nor), pa)) +
	sign(dot(cross(cb, nor), pb)) +
	sign(dot(cross(ac, nor), pc)) < 2.0)
	?
	min(min(
	dot2three(ba * clamp(dot(ba, pa) / dot2three(ba), 0.0, 1.0) - pa),
	dot2three(cb * clamp(dot(cb, pb) / dot2three(cb), 0.0, 1.0) - pb)),
	dot2three(ac * clamp(dot(ac, pc) / dot2three(ac), 0.0, 1.0) - pc))
	:
	dot(nor, pa) * dot(nor, pa) / dot2three(nor));
}

// Quad
float udQuad(float3 p, float3 a, float3 b, float3 c, float3 d)
{
	float3 ba = b - a; float3 pa = p - a;
	float3 cb = c - b; float3 pb = p - b;
	float3 dc = d - c; float3 pc = p - c;
	float3 ad = a - d; float3 pd = p - d;
	float3 nor = cross(ba, ad);

	return sqrt(
	(sign(dot(cross(ba, nor), pa)) +
	sign(dot(cross(cb, nor), pb)) +
	sign(dot(cross(dc, nor), pc)) +
	sign(dot(cross(ad, nor), pd)) < 3.0)
	?
	min(min(min(
	dot2three(ba * clamp(dot(ba, pa) / dot2three(ba), 0.0, 1.0) - pa),
	dot2three(cb * clamp(dot(cb, pb) / dot2three(cb), 0.0, 1.0) - pb)),
	dot2three(dc * clamp(dot(dc, pc) / dot2three(dc), 0.0, 1.0) - pc)),
	dot2three(ad * clamp(dot(ad, pd) / dot2three(ad), 0.0, 1.0) - pd))
	:
	dot(nor, pa) * dot(nor, pa) / dot2three(nor));
}


// Mandelbulb
float Mandelbulb(float3 pos, int Iterations, float Bailout, float Power) {
	float3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < Iterations ; i++) {
		r = length(z);
		if (r>Bailout) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y/z.x);
		dr =  pow( r, Power-1.0)*Power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,Power);
		theta = theta*Power;
		phi = phi*Power;
		
		// convert back to cartesian coordinates
		z = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return 0.5*log(r)*r/dr;
}

float4 MandelbulbColoured(float3 pos, int Iterations, float Bailout, float Power)
{
	float3 w = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < Iterations; i++) {
		r = length(w);
		if (r > Bailout) break;

		// convert to polar coordinates
		float theta = acos(w.z / r);
		float phi = atan(w.y / w.x);
		dr = pow(r, Power - 1.0) * Power * dr + 1.0;

		// scale and rotate the point
		float zr = pow(r, Power);
		theta = theta * Power;
		phi = phi * Power;

		// convert back to cartesian coordinates
		w = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		w += pos;
	}
	return float4(w.x, w.y, w.z, 0.5 * log(r) * r / dr);
}

// MandelbulbEscape
float2 MandelbulbEscape(float3 pos, int Iterations, float Bailout, float Power)
{
	float3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	float iteration = 0;
	for (int i = 0; i < Iterations; i++) {
		r = length(z);
		iteration = i;
		if (r > Bailout) break;

		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan(z.y / z.x);
		dr = pow(r, Power - 1.0) * Power * dr + 1.0;

		// scale and rotate the point
		float zr = pow(r, Power);
		theta = theta * Power;
		phi = phi * Power;

		// convert back to cartesian coordinates
		z = zr * float3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta));
		z += pos;
	}
	return float2(iteration, 0.5 * log(r) * r / dr);
}


// Menger Sponge
float2 MengerSponge(in float3 p, float b, int iteration)
{
	p = abs(p);
	float2 d = float2(sdBox(p, float3(b, b, b)), 0.0);
	float s = 1 / b;
	for (int m = 0; m < iteration; m++)
	{
		float3 a = fmod(p * s, 2.0) - 1.0;
		s *= 3.0;
		float3 r = abs(1.0 - 3.0 * abs(a));
		float c = sdCross(r, 1) / s;
		if (d.x < c) {
			d = float2(c, m);
		}
	}
	
	return d;
}


// OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

float4 opUColoured(float4 d1, float4 d2)
{
	return (d1.w < d2.w) ? d1 : d2;
}

float opSmoothUnion(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0, 1);
	return lerp( d2, d1, h) - k * h * (1.0 - h);
}

float4 opSmoothUnionColoured(float4 d1, float4 d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0, 1);
	float3 colour = lerp(d2.rgb, d1.rgb, h);
	float dist = lerp( d2.w, d1.w, h) - k * h * (1.0 - h);
	return float4(colour, dist);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

float opSmoothSubtraction(float d1, float d2, float k) {
	float h = max(k - abs(-d1 - d2), 0.0);
	return max(-d1, d2 + h * h * 0.25 * k);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

float opSmoothIntersection(float d1, float d2, float k) {
	float h = max(k - abs(d1 - d2), 0.0);
	return max(d1, d2) + h * h * 0.25 / k;
}


// COLORING
// cosineColor
float3 cosineColor(in float t, in float3 a, in float3 b, in float3 c, in float3 d)
{
	return a + b * cos(6.28318 * (c * t + d));
}
float3 palette(float t) {
	return cosineColor(t, float3(0.5, 0.5, 0.5), float3(0.5, 0.5, 0.5), float3(0.01, 0.01, 0.01), float3(0.0, 0.10, 0.10));
}