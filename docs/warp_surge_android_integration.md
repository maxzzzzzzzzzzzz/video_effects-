# Warp Surge — Android Studio Integration Handoff

`Warp Surge` is a fullscreen focal zoom-streak effect. It samples along the radial direction from a configurable focal point, averages the samples, and blends the result according to `uProgress`. This makes it suitable as a clip treatment or as a transition between two shots.

## Files

| File | Purpose |
|---|---|
| `effect.json` | Registry metadata and control definitions. |
| `warp_surge.glsl` | GLSL ES 1.00 fragment shader. |
| `preview.webp` | Effect-picker preview. |

## Required shared inputs

| Input | Type | Integration requirement |
|---|---|---|
| `sTexture` | `samplerExternalOES` | Bind the decoded or camera frame as `GL_TEXTURE_EXTERNAL_OES`. |
| `uTime` | `float` | Supply the shared animation time; it is retained for the common contract. |
| `uResolution` | `vec2` | Supply the output width and height in pixels. |
| `vTextureCoord` | `vec2` | Pass normalized coordinates from the existing fullscreen vertex shader. |

## Effect controls

| Uniform | Type | Default | Purpose |
|---|---|---:|---|
| `uAmount` | `float` | `32.0` | Maximum focal displacement in pixels. |
| `uCenter` | `vec2` | `(0.5, 0.5)` | Focal point of the surge in normalized coordinates. |
| `uStreakLength` | `float` | `1.0` | Length of the radial sample trail. |
| `uSamples` | `int` | `8` | Active radial samples from 2 through 10. |
| `uDirection` | `float` | `1.0` | Inward surge when below `0.5`; outward pull when at or above `0.5`. |
| `uProgress` | `float` | `1.0` | Transition progress from the original frame to the full streak. |
| `uEase` | `float` | `1.5` | Shapes the progress curve. |
| `uEdgeMode` | `float` | `0.0` | Clamps sample coordinates when below `0.5`; wraps them when at or above `0.5`. |

## Integration notes

For a transition, animate `uProgress` from `0.0` to `1.0` over the chosen transition duration using the app’s existing easing system. A reverse transition can animate from `1.0` back to `0.0` or switch `uDirection` depending on the desired visual direction. Keep `uCenter` near the subject or the intended entry point rather than assuming the frame center.

The shader applies aspect correction so the radial path is based on displayed pixel geometry. It clamps lookup coordinates by default, which is the safer setting for ordinary video. Enable wrapping only when the app intentionally wants the frame to repeat at the edges.

The loop has a fixed upper bound for GLSL ES 1.00 portability. If the app exposes quality tiers, map them to `uSamples` values such as 4, 8, and 10 rather than changing the shader source.

## Validation

Test `uProgress = 0` and confirm the output equals the original frame. Test the default progress with focal points at the center and near a corner. Verify that the surge direction reverses correctly and that clamped edges do not show black gaps.
