#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;
uniform float uPixelSize;
uniform float uPosterize;

void main() {
    // Pixel grid in screen space
    float size = mix(1.0, uPixelSize, uIntensity);
    vec2 grid = uResolution / size;
    vec2 uv = (floor(vTextureCoord * grid) + 0.5) / grid;

    vec3 color = texture2D(sTexture, uv).rgb;

    // Optional posterization for a retro palette look
    if (uPosterize > 0.5) {
        float levels = 8.0;
        color = floor(color * levels) / levels;
    }

    gl_FragColor = vec4(color, 1.0);
}
