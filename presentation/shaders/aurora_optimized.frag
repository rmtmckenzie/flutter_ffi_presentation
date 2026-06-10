#include <flutter/runtime_effect.glsl>

// --- Standard uniforms ---
uniform vec2 uResolution;    // index 0-1
uniform float uTime;         // index 2

// --- Custom uniforms ---
uniform float uIntensity;    // index 3, 0.0 - 1.0
uniform float uSpeed;        // index 4, multiplier
uniform vec3 uColor1;        // index 5-7, primary aurora color
uniform vec3 uColor2;        // index 8-10, secondary aurora color

out vec4 fragColor;

const float TAU = 6.28318530718;
const int AURORA_LAYERS = 4; // Reduced from 5 to 4 (20% less work, barely visible difference)

// Fast pseudo-random hash without heavy trigonometric scaling
float hash(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// Optimized value noise
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Simplified FBM (3 octaves instead of 5 is plenty for organic flow)
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    vec2 shift = vec2(100.0);
    // Unrolled for performance
    value += amplitude * noise(p); p = p * 2.0 + shift; amplitude *= 0.5;
    value += amplitude * noise(p); p = p * 2.0 + shift; amplitude *= 0.5;
    value += amplitude * noise(p);
    return value;
}

// Optimized Domain-warped FBM (Reduced noise lookups significantly)
float warpedFbm(vec2 p, float t) {
    vec2 q = vec2(
        noise(p + t * 0.15),
        noise(p + vec2(5.2, 1.3) + t * 0.12)
    );
    vec2 r = vec2(
        noise(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.1),
        noise(p + 4.0 * q + vec2(8.3, 2.8) + t * 0.08)
    );
    return fbm(p + 4.0 * r);
}

float auroraBand(vec2 uv, float yCenter, float t, float seed) {
    float warp = warpedFbm(vec2(uv.x * 1.5 + seed * 3.7, t * 0.2 + seed), t * 0.3);

    float verticalWave = sin(uv.x * 3.0 + t * 0.7 + seed * TAU) * 0.06;
    verticalWave += sin(uv.x * 7.0 - t * 0.4 + seed * 5.0) * 0.03;
    verticalWave += (warp - 0.5) * 0.12;

    float y = uv.y - yCenter - verticalWave;

    float bandWidth = 0.06 + warp * 0.04;
    // Fast approximation of exp(-x^2) using basic arithmetic or native exp
    float band = exp(-y * y / (2.0 * bandWidth * bandWidth));

    // Lower octave noise for shimmer
    float shimmer = noise(vec2(uv.x * 8.0 + t * 0.5, uv.y * 4.0 + seed * 10.0));
    band *= 0.5 + shimmer * 0.7;

    float curtainTrail = smoothstep(0.0, 0.15, y + 0.15) * exp(-max(y, 0.0) * 3.0);
    band += curtainTrail * 0.3 * shimmer;

    return band;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / uResolution;

    float t = uTime * uSpeed;
    vec3 color = vec3(0.0);
    float totalAlpha = 0.0;

    // Pre-calculate common mix colors outside loop
    vec3 midColorBase = mix(uColor1, uColor2, 0.5) + vec3(0.0, 0.08, 0.05);

    for (int i = 0; i < AURORA_LAYERS; i++) {
        float fi = float(i);
        float seed = fi * 0.73 + 0.1;
        float yCenter = 0.3 + fi * 0.08 + sin(t * 0.1 + fi * 1.5) * 0.04;

        float band = auroraBand(uv, yCenter, t, seed);
        float colorMix = sin(fi * 1.2 + t * 0.15) * 0.5 + 0.5;

        vec3 layerColor = (colorMix < 0.5)
            ? mix(uColor1, midColorBase, colorMix * 2.0)
            : mix(midColorBase, uColor2, (colorMix - 0.5) * 2.0);

        float layerAlpha = band * (1.0 - fi * 0.12);
        color += layerColor * layerAlpha;
        totalAlpha += layerAlpha;
    }

    color *= uIntensity;
    totalAlpha *= uIntensity;

    float verticalFade = smoothstep(1.0, 0.2, uv.y);
    color *= verticalFade;
    totalAlpha *= verticalFade;

    color += mix(uColor1, uColor2, 0.5) * (totalAlpha * 0.15);
    totalAlpha = clamp(totalAlpha, 0.0, 1.0);

    fragColor = vec4(color * totalAlpha, totalAlpha);
}