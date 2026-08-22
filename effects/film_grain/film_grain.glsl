#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;
uniform float uGrainSize;
uniform float uVignette;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
    vec2 uv = vTextureCoord;
    vec3 color = texture2D(sTexture, uv).rgb;

    // Animated monochrome grain
    vec2 grainUV = floor(uv * uResolution / max(uGrainSize, 1.0));
    float grain = hash(grainUV + fract(uTime)) - 0.5;
    color += grain * 0.15 * uIntensity;

    // Subtle warm fade for a filmic tone
    color = mix(color, color * vec3(1.05, 1.0, 0.92), 0.5 * uIntensity);

    // Vignette
    float dist = distance(uv, vec2(0.5));
    color *= 1.0 - dist * dist * uVignette;

    gl_FragColor = vec4(color, 1.0);
}
