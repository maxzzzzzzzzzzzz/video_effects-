#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uIntensity;
uniform vec3 uShadowColor;
uniform vec3 uHighlightColor;
uniform float uContrast;

void main() {
    vec3 color = texture2D(sTexture, vTextureCoord).rgb;

    // Luminance with contrast adjustment
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    luma = clamp((luma - 0.5) * uContrast + 0.5, 0.0, 1.0);

    // Map luminance onto the two-tone gradient
    vec3 duo = mix(uShadowColor, uHighlightColor, luma);

    gl_FragColor = vec4(mix(color, duo, uIntensity), 1.0);
}
