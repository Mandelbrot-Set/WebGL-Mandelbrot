
#define ITER_UPPER_BOUND 1000000

precision highp float;

varying vec2 fpos;

uniform vec3 clrRatio;
uniform int maxIter;
uniform vec2 pos;
uniform float zoom;
uniform mat4 rot;
uniform float aspectRatio;
uniform int mode;
uniform int innerMode;
uniform float var1;
uniform float cursor;

const float ln2 = log(2.0);

float sinh(float x) {
	return (exp(x) + exp(-x)) / 2.0;
}
float cosh(float x) {
	return (exp(x) - exp(-x)) / 2.0;
}

struct CNum {
	float re, im;
};
CNum cadd(CNum a, CNum b) {
	return CNum(a.re + b.re, a.im + b.im);
}
CNum csub(CNum a, CNum b) {
	return CNum(a.re - b.re, a.im - b.im);
}
CNum cmul(CNum a, CNum b) {
	return CNum(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re);
}
CNum csquare(CNum a) {
	return CNum(a.re * a.re - a.im * a.im, 2.0 * a.re * a.im);
}
CNum cdiv(CNum a, CNum b) {
	float den = b.re * b.re + b.im * b.im;
	return CNum((a.re * b.re + a.im * b.im) / den, (a.im * b.re + a.re * b.im) / den);
}
float cmodsq(CNum a) {
	return a.re * a.re + a.im * a.im;
}
float cmod(CNum a) {
	return sqrt(a.re * a.re + a.im * a.im);
}
CNum crecpcl(CNum a) {
	float den = cmodsq(a);
	if (den == 0.0) {
		return CNum(0.0, 0.0);
	} else {
		return CNum(a.re / den, -a.im / den);
	}
}
float carg(CNum a) {
	return atan(a.im, a.re);
}
CNum cpow(CNum a, float b) {
	float r = cmod(a);
	float p = carg(a);
	float c = pow(r, b);
	float d = b * p;
	return CNum(c * cos(d), c * sin(d));
}
CNum cpow(CNum a, CNum b) {
	if (b.re == 0.0 && b.im == 0.0) return CNum(1.0, 0.0);
	if (b.im == 0.0) return cpow(a, b.re);
	float r = cmod(a);
	float p = carg(a);
	float c = b.im * log(r) + b.re * p;
	float d = pow(r, b.re) * exp(-b.im * p);
	return CNum(d * cos(c), d * sin(c));
}
CNum cpolar(float r, float theta) {
	return CNum(r * cos(theta), r * sin(theta));
}
CNum csin(CNum a) {
	return CNum(sin(a.re) * cosh(a.im), cos(a.re) * sinh(a.im));
}
CNum ccos(CNum a) {
	return CNum(cos(a.re) * cosh(a.im), -sinh(a.im) * sin(a.re));
}
CNum ctan(CNum a) {
	float den = cos(2.0 * a.re) + cosh(2.0 * a.im);
	return CNum(sin(2.0 * a.re) / den, sinh(2.0 * a.im) / den);
}
CNum csinh(CNum a) {
	return CNum(cosh(a.re) * cos(a.im), sinh(a.re) * sin(a.im));
}
CNum ccosh(CNum a) {
	return CNum(sinh(a.re) * cos(a.im), cosh(a.re) * sin(a.im));
}
CNum ctanh(CNum a) {
	float den = cosh(2.0 * a.re) + cos(2.0 * a.im);
	return CNum(sinh(2.0 * a.re) / den, sin(2.0 * a.im) / den);
}
CNum cln(CNum a) {
	return CNum(log(cmod(a)), carg(a));
}
CNum clog(CNum a, CNum b) {
	return cdiv(cln(a), cln(b));
}

float calcIter1(CNum c) {
	CNum z = CNum(0.0, 0.0);
	for (int i = 0; i < ITER_UPPER_BOUND; i++) {
		if (i >= maxIter) break;
		z = csquare(z);
		z = cadd(z, c);
		if (cmodsq(z) > 4.0) {
			z = csquare(z);
			z = cadd(z, c);
			z = csquare(z);
			z = cadd(z, c);
			float mod = cmod(z);
			if (mod <= 1.0) return float(i);
			float mu = float(i) - log(log(mod)) / ln2;
			if (mu < 0.0) return 0.0;
			return mu;
		}
	}
	return float(maxIter);
}
float calcIter2(CNum c) {
	CNum z = CNum(0.0, 0.0);
	for (int i = 0; i < ITER_UPPER_BOUND; i++) {
		if (i >= maxIter) break;
		z = csquare(z);
		z = cadd(z, c);
     	z = crecpcl(z);
		if (cmodsq(z) > 4.0) {
			z = csquare(z);
			z = cadd(z, c);
			z = csquare(z);
			z = cadd(z, c);
			float mod = cmod(z);
			if (mod <= 1.0) return float(i);
			float mu = float(i) - log(log(mod)) / ln2;
			if (mu < 0.0) return 0.0;
			return mu;
		}
	}
	return float(maxIter);
}
float calcIter3(CNum c) {
	CNum z = CNum(0.0, 0.0);

	for (int i = 0; i < ITER_UPPER_BOUND; i++) {
		if (i >= maxIter) break;
		z = csquare(z);
		z = cadd(z, c);
     	z = ccos(z);
		if (cmodsq(z) > 4.0) {
			z = csquare(z);
			z = cadd(z, c);
			z = csquare(z);
			z = cadd(z, c);
			float mod = cmod(z);
			if (mod <= 1.0) return float(i);
			float mu = float(i) - log(log(mod)) / ln2;
			if (mu < 0.0) return 0.0;
			return mu;
		}
	}
	return float(maxIter);
}
float calcIter(CNum c) {
	if (mode == 2) {
		c = crecpcl(c);
	} else if (mode == 3) {
		c = ccos(c);
	} else if (mode == 4) {
		c = ctan(c);
	} else if (mode == 5) {
		c = cpow(c, CNum(var1, 0.0));
	} else if (mode == 6) {
		c = csin(c);
	} else if (mode == 7) {
		c = clog(c, CNum(var1, 0.0));
	} else if (mode == 8) {
		c = ctan(c);
	} else if (mode == 9) {
		c = cmul(crecpcl(c), clog(c, CNum(var1, 0.0)));
	}

	if (innerMode == 1) return calcIter1(c);
	else if (innerMode == 2) return calcIter2(c);
	else if (innerMode == 3) return calcIter3(c);
  	else return 0.0;
}

void main(void) {
    vec4 frag = vec4(0.0, 0.0, 0.0, 1.0);
    vec2 z = fpos;
    bool line = false;
    if (
    (abs(z.x + 0.5) < 0.001 || abs(z.y) < 0.001 * aspectRatio) &&
    ((z.x + 0.5) * (z.x + 0.5) + (z.y / aspectRatio) * (z.y / aspectRatio) <= 0.001)
    ) line = true;
    z.y /= aspectRatio;
    z.x += 0.5;
    z = (vec4(z, 0.0, 1.0) * rot).xy;
    z.x *= zoom;
    z.y *= zoom;
    z += pos;
    CNum c = CNum(z.x, z.y);
    float iter = calcIter(c);
    vec3 clr = vec3((-cos(clrRatio.x*iter)+1.0)/2.0, (-cos(clrRatio.y*iter)+1.0)/2.0, (-cos(clrRatio.z*iter)+1.0)/2.0);
    if (iter == float(maxIter)) frag = vec4(0.0, 0.0, 0.0, 1.0);
    else frag = vec4(clr, 1.0);
    if (line) {
        frag.x = mix(1.0 - frag.x, frag.x, cursor);
        frag.y = mix(1.0 - frag.y, frag.y, cursor);
        frag.z = mix(1.0 - frag.z, frag.z, cursor);
    }
    gl_FragColor = frag;
}

