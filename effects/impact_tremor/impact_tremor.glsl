#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uAmplitude;
uniform float uFrequency;
uniform float uRotationAmount;
uniform float uScaleAmount;
uniform float uDecay;
uniform float uSeed;
uniform float uMix;

float hash(float value) {
    return fract(sin(value * 12.9898 + 78.233) * 43758.5453);
}

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.001), vec2(0.999));
}

void main() {
    vec2 uv = vTextureCoord;
    vec2 texel = 1.0 / max(uResolution, vec2(1.0));
    float frequency = max(uFrequency, 0.05);
    float cycle = fract(uTime * frequency);
    float envelope = pow(1.0 - cycle, max(uDecay, 0.05));
    float sampleTick = floor(uTime * frequency * 4.0);

    vec2 randomOffset = vec2(
        hash(sampleTick + uSeed),
        hash(sampleTick + uSeed + 19.17)
    ) - 0.5;
    vec2 offset = randomOffset * max(uAmplitude, 0.0) * texel * envelope;
    float rotation = (hash(sampleTick + uSeed + 41.3) - 0.5)
                   * max(uRotationAmount, 0.0) * envelope;
    float scale = 1.0 + (hash(sampleTick + uSeed + 67.9) - 0.5)
                        * max(uScaleAmount, 0.0) * envelope;

    vec2 center = vec2(0.5);
    vec2 shaken = (uv - center - offset) / max(scale, 0.01);
    float sine = sin(rotation);
    float cosine = cos(rotation);
    shaken = vec2(
        shaken.x * cosine - shaken.y * sine,
        shaken.x * sine + shaken.y * cosine
    ) + center;

    vec3 original = texture2D(sTexture, clampUV(uv)).rgb;
    vec3 displaced = texture2D(sTexture, clampUV(shaken)).rgb;
    vec3 result = mix(original, displaced, clamp(uMix, 0.0, 1.0));
    gl_FragColor = vec4(result, 1.0);
}
