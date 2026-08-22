#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uAmount;
uniform vec2 uDirection;
uniform int uSamples;
uniform float uPositionInfluence;
uniform float uScaleInfluence;
uniform float uRotationInfluence;
uniform float uMix;

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.001), vec2(0.999));
}

void main() {
    vec2 uv = vTextureCoord;
    vec2 texel = 1.0 / max(uResolution, vec2(1.0));
    vec2 fallbackDirection = uDirection;
    float directionLength = length(fallbackDirection);
    fallbackDirection = directionLength > 0.0001
        ? fallbackDirection / directionLength
        : vec2(1.0, 0.0);

    float transformInfluence = clamp(
        (uPositionInfluence + uScaleInfluence + uRotationInfluence) / 3.0,
        0.0,
        1.0
    );
    vec2 blurVector = fallbackDirection * texel * max(uAmount, 0.0) * transformInfluence;
    float sampleCount = clamp(float(uSamples), 2.0, 8.0);
    vec3 sum = vec3(0.0);
    float weightSum = 0.0;

    // Fixed loop bounds keep the shader friendly to GLSL ES 1.00 compilers.
    // The active mask allows the UI to select a smaller sample count.
    for (int i = 0; i < 8; i++) {
        float index = float(i);
        float t = (index / 7.0) * 2.0 - 1.0;
        float enabledSample = step(index + 0.5, sampleCount);
        vec2 tapUV = uv + blurVector * t;
        float centerWeight = 1.0 - abs(t) * 0.35;
        sum += texture2D(sTexture, clampUV(tapUV)).rgb * centerWeight * enabledSample;
        weightSum += centerWeight * enabledSample;
    }

    vec3 blurred = sum / max(weightSum, 0.0001);
    vec3 original = texture2D(sTexture, clampUV(uv)).rgb;
    vec3 result = mix(original, blurred, clamp(uMix, 0.0, 1.0));
    gl_FragColor = vec4(result, 1.0);
}
