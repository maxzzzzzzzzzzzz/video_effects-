#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;
uniform float uBlockSize;
uniform float uSpeed;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.0), vec2(1.0));
}

void main() {
    vec2 uv = vTextureCoord;
    float t = floor(uTime * uSpeed * 10.0);

    // Block displacement
    float blockRows = mix(4.0, 32.0, 1.0 - uBlockSize);
    float row = floor(uv.y * blockRows);
    float rnd = hash(vec2(row, t));
    float displace = (rnd - 0.5) * 0.1 * uIntensity * step(0.7, rnd);
    uv.x += displace;

    // Occasional vertical roll
    float roll = step(0.95, hash(vec2(t, 3.0))) * hash(vec2(t, 7.0)) * 0.2 * uIntensity;
    uv.y = fract(uv.y + roll);

    // RGB split on displaced blocks
    float split = 0.008 * uIntensity * (0.5 + abs(displace) * 20.0);
    float r = texture2D(sTexture, clampUV(uv + vec2(split, 0.0))).r;
    float g = texture2D(sTexture, clampUV(uv)).g;
    float b = texture2D(sTexture, clampUV(uv - vec2(split, 0.0))).b;

    gl_FragColor = vec4(r, g, b, 1.0);
}
