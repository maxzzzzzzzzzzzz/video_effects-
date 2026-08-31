#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTextureFrom;
uniform samplerExternalOES sTextureTo;
uniform float uProgress;
uniform vec2 uResolution;
uniform float uAngle;
uniform float uSoftness;

void main() {
    vec2 uv = vTextureCoord;

    vec3 from = texture2D(sTextureFrom, uv).rgb;
    vec3 to = texture2D(sTextureTo, uv).rgb;

    float rad = radians(uAngle);
    vec2 dir = vec2(cos(rad), sin(rad));

    // Position of the pixel along the wipe axis, normalised to 0..1 so the
    // wipe fully covers the frame at any angle.
    vec2 centered = uv - 0.5;
    float extent = abs(dir.x) * 0.5 + abs(dir.y) * 0.5;
    float pos = (dot(centered, dir) + extent) / (2.0 * extent);

    float softness = max(uSoftness, 0.001);
    float front = uProgress * (1.0 + softness);
    float blend = smoothstep(front - softness, front, pos);

    gl_FragColor = vec4(mix(to, from, blend), 1.0);
}
