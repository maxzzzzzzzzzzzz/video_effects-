#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uAmount;
uniform vec2 uCenter;
uniform float uStreakLength;
uniform int uSamples;
uniform float uDirection;
uniform float uProgress;
uniform float uEase;
uniform float uEdgeMode;

vec2 sampleUV(vec2 uv) {
    if (uEdgeMode > 0.5) {
        return fract(uv);
    }
    return clamp(uv, vec2(0.001), vec2(0.999));
}

void main() {
    vec2 uv = vTextureCoord;
    vec2 center = clamp(uCenter, vec2(0.0), vec2(1.0));
    float aspect = uResolution.x / max(uResolution.y, 1.0);
    vec2 toPixel = uv - center;
    vec2 aspectVector = vec2(toPixel.x * aspect, toPixel.y);
    float distanceFromCenter = length(aspectVector);
    vec2 radial = distanceFromCenter > 0.0001
        ? vec2(aspectVector.x / aspect, aspectVector.y) / distanceFromCenter
        : vec2(0.0);

    float progress = clamp(uProgress, 0.0, 1.0);
    float easedProgress = pow(progress, max(uEase, 0.1));
    float signedAmount = mix(-1.0, 1.0, step(0.5, uDirection))
                       * max(uAmount, 0.0)
                       * easedProgress;
    float sampleCount = clamp(float(uSamples), 2.0, 10.0);
    vec3 sum = vec3(0.0);
    float weightSum = 0.0;

    // Fixed bounds keep this loop compatible with GLSL ES 1.00 drivers.
    for (int i = 0; i < 10; i++) {
        float index = float(i);
        float t = index / 9.0;
        float enabledSample = step(index + 0.5, sampleCount);
        float centeredT = t - 0.5;
        vec2 tapUV = uv + radial * centeredT * signedAmount * uStreakLength;
        float weight = 1.0 - abs(centeredT) * 0.35;
        sum += texture2D(sTexture, sampleUV(tapUV)).rgb * weight * enabledSample;
        weightSum += weight * enabledSample;
    }

    vec3 base = texture2D(sTexture, sampleUV(uv)).rgb;
    vec3 warped = sum / max(weightSum, 0.0001);
    gl_FragColor = vec4(mix(base, warped, progress), 1.0);
}
