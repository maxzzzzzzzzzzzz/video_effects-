# Prism Bloom — Android Studio Integration Handoff

## Purpose

`Prism Bloom` is a full-frame post-processing effect for the `video_effects-` registry. It samples the app-provided external video texture, extracts bright pixels, diffuses those highlights with lightweight multi-tap sampling, tints the emitted light, and composites it over the original frame.

The implementation follows the repository’s required effect layout: `effect.json`, `prism_bloom.glsl`, and `preview.webp`. The registry entry points to those files and leaves `sha256` empty for CI to populate after merge.[1]

## Files

| File | Role |
|---|---|
| `effects/prism_bloom/effect.json` | Effect identity, UI descriptions, defaults, Android compatibility, and shader parameter contract. |
| `effects/prism_bloom/prism_bloom.glsl` | GLSL ES 1.00 fragment shader. |
| `effects/prism_bloom/preview.webp` | 640 × 360 picker preview showing warm, cool, and magenta bloom sources. |
| `registry.json` | Top-level discovery entry for the app. |

## Rendering contract

The shader expects the same baseline inputs used by the existing repository effects:

| Input | GLSL type | Source in the Android renderer | Required behavior |
|---|---|---|---|
| `sTexture` | `samplerExternalOES` | The camera, decoder, or video surface texture | Bind as an external OES texture before drawing. |
| `uTime` | `float` | Current animation time in seconds | Supply a monotonically increasing value. Prism Bloom is currently static, but the uniform is part of the shared contract. |
| `uResolution` | `vec2` | Render-target width and height in pixels | Supply the actual dimensions of the framebuffer or effect render target. |
| `vTextureCoord` | `vec2` varying | Existing fullscreen-quad vertex shader | Pass normalized texture coordinates in the range 0–1. |

The extension declaration is required because the repository targets Android external textures through `GL_OES_EGL_image_external`. Android exposes this extension through the OpenGL ES extension bindings.[2]

## Effect uniforms

The following uniforms correspond one-to-one with the `parameters` array in `effect.json`. The app should locate each uniform after linking the program and update it before drawing.

| Uniform | Type | Default | Range | UI meaning |
|---|---|---:|---:|---|
| `uThreshold` | `float` | `0.68` | `0.0–1.0` | Brightness level at which pixels begin to emit bloom. Higher values restrict bloom to brighter sources. |
| `uDiffusion` | `float` | `12.0` | `0.0–40.0` | Spread radius in pixels. Higher values create a wider, softer bloom. |
| `uIntensity` | `float` | `0.85` | `0.0–2.0` | Brightness of the bloom contribution. |
| `uColor` | `vec3` | `(1.0, 0.78, 0.48)` | RGB 0–1 | Color toward which extracted light is tinted. |
| `uBlend` | `float` | `0.35` | `0.0–1.0` | Mix between the source highlight color and `uColor`. |
| `uHalo` | `float` | `0.55` | `0.0–1.0` | Strength of the wider secondary halo. |
| `uAlpha` | `float` | `1.0` | `0.0–1.0` | Overall bloom opacity. |

## Recommended Android render sequence

The effect is designed to work in the same fullscreen post-processing pass as the current registry shaders. The host renderer should use the following order:

1. Compile `prism_bloom.glsl` as a fragment shader with the application’s existing fullscreen-quad vertex shader.
2. Link the shader program and query the locations for `sTexture`, `uTime`, `uResolution`, and the seven effect uniforms listed above.
3. Bind the video frame to the external OES texture target. Do not bind it as a normal `GL_TEXTURE_2D` texture.
4. Set the viewport to the actual output framebuffer dimensions and update `uResolution` with those same pixel dimensions.
5. Bind the fullscreen vertex buffer and supply normalized `vTextureCoord` values using the same orientation convention as the existing effects.
6. Set effect parameters from the editor controls. Start with the defaults from `effect.json` to match the picker preview’s intended behavior.
7. Draw the fullscreen primitive. The shader outputs an opaque RGBA color with the bloom composited over the source frame.

## Kotlin-style uniform mapping example

The following is an integration pattern, not a new repository requirement. It assumes the app already owns shader compilation, program binding, external-texture setup, and fullscreen-quad drawing.

```kotlin
// Query once after program linking.
val uTime = GLES20.glGetUniformLocation(program, "uTime")
val uResolution = GLES20.glGetUniformLocation(program, "uResolution")
val uThreshold = GLES20.glGetUniformLocation(program, "uThreshold")
val uDiffusion = GLES20.glGetUniformLocation(program, "uDiffusion")
val uIntensity = GLES20.glGetUniformLocation(program, "uIntensity")
val uColor = GLES20.glGetUniformLocation(program, "uColor")
val uBlend = GLES20.glGetUniformLocation(program, "uBlend")
val uHalo = GLES20.glGetUniformLocation(program, "uHalo")
val uAlpha = GLES20.glGetUniformLocation(program, "uAlpha")

GLES20.glUseProgram(program)
GLES20.glUniform1f(uTime, timeSeconds)
GLES20.glUniform2f(uResolution, outputWidth.toFloat(), outputHeight.toFloat())
GLES20.glUniform1f(uThreshold, 0.68f)
GLES20.glUniform1f(uDiffusion, 12.0f)
GLES20.glUniform1f(uIntensity, 0.85f)
GLES20.glUniform3f(uColor, 1.0f, 0.78f, 0.48f)
GLES20.glUniform1f(uBlend, 0.35f)
GLES20.glUniform1f(uHalo, 0.55f)
GLES20.glUniform1f(uAlpha, 1.0f)

// Bind the decoded/camera frame to GL_TEXTURE_EXTERNAL_OES before drawing.
drawFullscreenQuad()
```

## Coordinate and orientation notes

The shader assumes that `vTextureCoord` already follows the project’s established video orientation. If the app’s preview and export paths use different vertical orientation conventions, correct the texture-coordinate transform in the shared vertex stage or texture-matrix path rather than adding a one-off flip inside Prism Bloom. This keeps the effect consistent with VHS, CRT, Film Grain, and the other registry entries.

The shader clamps its sample coordinates to a small interior margin. This prevents diffusion taps from sampling outside the valid external-texture range at the frame edges. The output is clamped to `[0, 1]` after additive compositing so bright sources do not produce invalid display values.

## Performance considerations

Prism Bloom uses a compact single-pass approximation: one base sample, a nine-tap near-field highlight spread, and four wider halo taps. The app should expose the sample count only if the renderer later supports a quality tier; the current shader intentionally keeps the quality contract fixed so it remains predictable on Android devices.

The most expensive control is `uDiffusion` because larger radii increase the distance between texture samples. For lower-end devices, the host can reduce the maximum UI value or use a lower-resolution intermediate framebuffer while preserving the same uniform contract. Avoid rendering the effect repeatedly when the source frame and parameters have not changed.

## Validation checklist

Before integration, confirm the following:

| Check | Expected result |
|---|---|
| Registry discovery | `registry.json` contains an entry with ID `prism_bloom`. |
| Metadata | `effect.json` mirrors the registry name, description, version, category, and tags. |
| Shader language | The shader remains GLSL ES 1.00 and keeps the external OES extension declaration. |
| Uniforms | Every parameter ID in `effect.json` has a matching `uniform` declaration. |
| Texture binding | The renderer binds the video source as `GL_TEXTURE_EXTERNAL_OES`. |
| Resolution | `uResolution` receives the actual target width and height in pixels. |
| Preview | `preview.webp` exists and displays a recognizable warm/cool highlight bloom. |
| Repository validator | `python3 scripts/validate_registry.py` reports the registry and seven effects as valid. |
| CI | The pull-request validation workflow passes before merge. |

## Known limitation and future extension

This first version operates on the complete frame and does not use a separate highlight render target or host-provided blur pyramid. That keeps it portable across the current registry contract. A future renderer can add a multi-pass quality mode without changing the effect’s public parameter names: extract highlights, downsample, blur at one or more radii, then composite the result using the same controls.

## References

[1]: https://github.com/maxzzzzzzzzzzzz/video_effects-/blob/main/README.md "video_effects- README and effect schema"
[2]: https://developer.android.com/reference/android/opengl/GLES11Ext "Android GLES11Ext reference"
