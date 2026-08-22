#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;
uniform float uCurvature;
uniform float uMaskStrength;

void main() {
    // Barrel distortion
    vec2 uv = vTextureCoord * 2.0 - 1.0;
    float r2 = dot(uv, uv);
    uv *= 1.0 + uCurvature * r2 * 0.15;
    uv = uv * 0.5 + 0.5;

    // Black outside the curved screen
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    vec3 color = texture2D(sTexture, uv).rgb;

    // RGB phosphor mask
    float px = uv.x * uResolution.x;
    vec3 mask = vec3(1.0);
    float m = mod(px, 3.0);
    if (m < 1.0) mask = vec3(1.0, 0.6, 0.6);
    else if (m < 2.0) mask = vec3(0.6, 1.0, 0.6);
    else mask = vec3(0.6, 0.6, 1.0);
    color *= mix(vec3(1.0), mask, uMaskStrength * uIntensity);

    // Scanlines
    float scan = sin(uv.y * uResolution.y * 3.14159) * 0.5 + 0.5;
    color *= mix(1.0, 0.75 + 0.25 * scan, uIntensity);

    // Slight flicker
    color *= 1.0 - 0.02 * uIntensity * sin(uTime * 60.0);

    gl_FragColor = vec4(color, 1.0);
}
