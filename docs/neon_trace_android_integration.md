# Neon Trace — Android Studio Integration Handoff

`Neon Trace` is a fullscreen edge-emphasis effect. It estimates luminance changes between neighboring pixels, thresholds those changes into a contour mask, samples nearby contours for a softer spread, tints the mask, and adds it over the original frame.

## Files

| File | Purpose |
|---|---|
| `effect.json` | Registry metadata and control definitions. |
| `neon_trace.glsl` | GLSL ES 1.00 fragment shader. |
| `preview.webp` | Effect-picker preview. |

## Required shared inputs

| Input | Type | Integration requirement |
|---|---|---|
| `sTexture` | `samplerExternalOES` | Bind the video frame as `GL_TEXTURE_EXTERNAL_OES`. |
| `uTime` | `float` | Supply the shared animation time; it is retained for the common contract and may be optimized out by the driver because the current look is static. |
| `uResolution` | `vec2` | Supply the output width and height in pixels. |
| `vTextureCoord` | `vec2` | Pass normalized coordinates from the existing fullscreen vertex shader. |

## Effect controls

| Uniform | Type | Default | Purpose |
|---|---|---:|---|
| `uThreshold` | `float` | `0.22` | Minimum contour strength needed to create neon lines. |
| `uBlur` | `float` | `2.0` | Pixel spacing used for edge detection and softening. |
| `uSpread` | `float` | `0.85` | Brightness and thickness of the neon result. |
| `uColor` | `vec3` | `(0.1, 0.8, 1.0)` | Neon contour color. |
| `uGamma` | `float` | `1.0` | Tonal curve applied before edge measurement. |
| `uInvert` | `float` | `0.0` | Reverses the contour mask when above `0.5`. |
| `uAlpha` | `float` | `0.9` | Opacity of the contour layer. |

## Integration notes

The shader performs several neighboring texture reads per pixel, so it is more expensive than a simple color effect. Use the defaults for normal preview quality and consider lowering the render-target resolution on low-end devices. The effect clamps all lookup coordinates to the valid texture range.

The `uThreshold` value controls the main artistic tradeoff. Lower values reveal more texture and compression detail; higher values keep only strong silhouettes and large contours. `uGamma` can be used to favor darker or brighter structural edges without modifying the original frame’s final color directly.

Any vertical flip or camera transform should be handled by the shared vertex texture matrix. The host should not alter the shader source when switching between preview and export.

## Validation

Test against a clean image with a distinct subject and a flat background. Verify that raising `uThreshold` reduces fine contours, `uAlpha = 0` restores the original frame, and `uInvert = 1` produces the intentionally reversed treatment. Check that dark backgrounds do not become uniformly filled with neon.
