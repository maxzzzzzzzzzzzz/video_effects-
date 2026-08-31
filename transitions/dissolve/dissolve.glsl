#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTextureFrom;
uniform samplerExternalOES sTextureTo;
uniform float uProgress;
uniform vec2 uResolution;
uniform float uSoftness;
uniform float uGrain;

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = vTextureCoord;

    vec3 from = texture2D(sTextureFrom, uv).rgb;
    vec3 to = texture2D(sTextureTo, uv).rgb;

    // Per-pixel threshold: grain 0 is a plain cross dissolve, higher values
    // break the blend front into a speckled film-burn style dissolve.
    float softness = max(uSoftness, 0.001);
    float edge = noise(floor(uv * uResolution)) * uGrain;

    // The front sweeps the whole threshold range plus one edge width, so the
    // blend is exactly 0 at progress 0 and exactly 1 at progress 1.
    float front = uProgress * (uGrain + softness);
    float blend = smoothstep(edge, edge + softness, front);

    gl_FragColor = vec4(mix(from, to, blend), 1.0);
}
