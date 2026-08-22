#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uThreshold;
uniform float uDiffusion;
uniform float uIntensity;
uniform vec3 uColor;
uniform float uBlend;
uniform float uHalo;
uniform float uAlpha;

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.001), vec2(0.999));
}

vec3 highlight(vec2 uv) {
    vec3 sampleColor = texture2D(sTexture, clampUV(uv)).rgb;
    float luminance = dot(sampleColor, vec3(0.2126, 0.7152, 0.0722));
    float thresholdWidth = 0.08 + 0.08 * (1.0 - uThreshold);
    float mask = smoothstep(uThreshold - thresholdWidth,
                            uThreshold + thresholdWidth,
                            luminance);
    return sampleColor * mask;
}

void main() {
    vec2 uv = vTextureCoord;
    vec3 base = texture2D(sTexture, clampUV(uv)).rgb;

    // Convert the diffusion amount from pixels to normalized texture space.
    vec2 texel = 1.0 / max(uResolution, vec2(1.0));
    vec2 radius = texel * max(uDiffusion, 0.0);

    // Nine-tap near-field bloom. The center is weighted more heavily to keep
    // bright sources crisp while the surrounding taps create the soft spread.
    vec3 core = highlight(uv) * 2.0;
    core += highlight(uv + vec2(radius.x, 0.0));
    core += highlight(uv - vec2(radius.x, 0.0));
    core += highlight(uv + vec2(0.0, radius.y));
    core += highlight(uv - vec2(0.0, radius.y));
    core += highlight(uv + vec2(radius.x, radius.y)) * 0.8;
    core += highlight(uv + vec2(-radius.x, radius.y)) * 0.8;
    core += highlight(uv + vec2(radius.x, -radius.y)) * 0.8;
    core += highlight(uv - vec2(radius.x, radius.y)) * 0.8;
    core /= 9.2;

    // Four wider taps form the optional halo without requiring a second render
    // target, keeping the effect practical for a mobile fragment pipeline.
    vec2 wideRadius = radius * 3.0;
    vec3 wide = highlight(uv + vec2(wideRadius.x, 0.0));
    wide += highlight(uv - vec2(wideRadius.x, 0.0));
    wide += highlight(uv + vec2(0.0, wideRadius.y));
    wide += highlight(uv - vec2(0.0, wideRadius.y));
    wide *= 0.25;

    // Tint the extracted light while retaining some of its source color.
    vec3 tintMultiplier = mix(vec3(1.0), uColor, clamp(uBlend, 0.0, 1.0));
    vec3 nearGlow = core * tintMultiplier;
    vec3 farGlow = wide * tintMultiplier;

    float effectStrength = max(uIntensity, 0.0) * clamp(uAlpha, 0.0, 1.0);
    vec3 result = base + nearGlow * effectStrength;
    result += farGlow * effectStrength * clamp(uHalo, 0.0, 1.0) * 0.65;

    // Keep the output in the legal display range after additive compositing.
    gl_FragColor = vec4(clamp(result, 0.0, 1.0), 1.0);
}
