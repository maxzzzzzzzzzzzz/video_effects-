#extension GL_OES_EGL_image_external : require
precision mediump float;

varying vec2 vTextureCoord;
uniform samplerExternalOES sTexture;
uniform float uTime;
uniform vec2 uResolution;
uniform float uThreshold;
uniform float uBlur;
uniform float uSpread;
uniform vec3 uColor;
uniform float uGamma;
uniform float uInvert;
uniform float uAlpha;

vec2 clampUV(vec2 uv) {
    return clamp(uv, vec2(0.001), vec2(0.999));
}

float lumaAt(vec2 uv) {
    vec3 color = texture2D(sTexture, clampUV(uv)).rgb;
    color = pow(clamp(color, 0.0, 1.0), vec3(max(uGamma, 0.01)));
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float edgeAt(vec2 uv, vec2 stepUV) {
    float left = lumaAt(uv - vec2(stepUV.x, 0.0));
    float right = lumaAt(uv + vec2(stepUV.x, 0.0));
    float down = lumaAt(uv - vec2(0.0, stepUV.y));
    float up = lumaAt(uv + vec2(0.0, stepUV.y));
    return length(vec2(right - left, up - down));
}

float contourAt(vec2 uv, vec2 stepUV) {
    float edge = edgeAt(uv, stepUV);
    float width = 0.08 + 0.18 * (1.0 - clamp(uThreshold, 0.0, 1.0));
    float mask = smoothstep(uThreshold, uThreshold + width, edge);
    return mix(mask, 1.0 - mask, step(0.5, uInvert));
}

void main() {
    vec2 uv = vTextureCoord;
    vec2 texel = 1.0 / max(uResolution, vec2(1.0));
    vec2 edgeStep = texel * max(uBlur, 1.0);
    float mask = contourAt(uv, edgeStep) * 2.0;
    vec2 spreadStep = edgeStep * 1.6;
    mask += contourAt(uv + vec2(spreadStep.x, 0.0), edgeStep);
    mask += contourAt(uv - vec2(spreadStep.x, 0.0), edgeStep);
    mask += contourAt(uv + vec2(0.0, spreadStep.y), edgeStep);
    mask += contourAt(uv - vec2(0.0, spreadStep.y), edgeStep);
    mask /= 6.0;

    vec3 base = texture2D(sTexture, clampUV(uv)).rgb;
    vec3 neon = uColor * mask * max(uSpread, 0.0) * clamp(uAlpha, 0.0, 1.0);
    vec3 result = clamp(base + neon, 0.0, 1.0);
    gl_FragColor = vec4(result, 1.0);
}
