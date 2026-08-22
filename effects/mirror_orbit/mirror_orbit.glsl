#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uSegments;
uniform vec2 uCenter;
uniform float uRotation;
uniform float uZoom;
uniform float uMirrorMode;
uniform float uFeather;
uniform float uMix;

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.001), vec2(0.999));
}

void main() {
    vec2 uv = vTextureCoord;
    vec2 center = clamp(uCenter, vec2(0.0), vec2(1.0));
    float aspect = uResolution.x / max(uResolution.y, 1.0);
    vec2 centered = (uv - center) * vec2(aspect, 1.0);
    float radius = length(centered);
    float angle = atan(centered.y, centered.x) + 3.14159265 + uRotation;
    float fullTurn = 6.28318530;
    angle = mod(angle, fullTurn);

    float segments = max(uSegments, 1.0);
    float sectorSize = fullTurn / segments;
    float sectorIndex = floor(angle / sectorSize);
    float localAngle = mod(angle, sectorSize);
    float mirrored = step(0.5, mod(sectorIndex, 2.0)) * step(0.5, uMirrorMode);
    localAngle = mix(localAngle, sectorSize - localAngle, mirrored);

    float edgeDistance = min(localAngle, sectorSize - localAngle);
    float featherWidth = max(uFeather, 0.001) * sectorSize * 0.5;
    float seam = smoothstep(0.0, featherWidth, edgeDistance);
    float sourceAngle = localAngle + 3.14159265 - sectorSize * 0.5;
    vec2 warped = vec2(cos(sourceAngle), sin(sourceAngle)) * radius * max(uZoom, 0.01);
    warped.x /= max(aspect, 0.001);
    vec2 sourceUV = center + warped;

    vec3 original = texture2D(sTexture, clampUV(uv)).rgb;
    vec3 transformed = texture2D(sTexture, clampUV(sourceUV)).rgb;
    float amount = clamp(uMix * mix(0.55, 1.0, seam), 0.0, 1.0);
    vec3 result = mix(original, transformed, amount);
    gl_FragColor = vec4(result, 1.0);
}
