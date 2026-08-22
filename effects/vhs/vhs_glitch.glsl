#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;
uniform float uScanlineDensity;
uniform float uSplitAmount;

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.0), vec2(1.0));
}

void main() {
    vec2 uv = vTextureCoord;

    // Horizontal jitter
    float jitter = (noise(vec2(uTime, uv.y)) - 0.5) * 0.02 * uIntensity;
    uv.x += jitter;

    // RGB split
    float split = 0.01 * uSplitAmount * uIntensity;
    float r = texture2D(sTexture, clampUV(uv + vec2(split, 0.0))).r;
    float g = texture2D(sTexture, clampUV(uv)).g;
    float b = texture2D(sTexture, clampUV(uv - vec2(split, 0.0))).b;

    vec3 color = vec3(r, g, b);

    // Scanning lines (density in lines per screen height)
    float lines = uResolution.y * uScanlineDensity;
    float scanline = sin(uv.y * lines * 3.14159) * 0.04 * uIntensity;
    color -= scanline;

    gl_FragColor = vec4(color, 1.0);
}
