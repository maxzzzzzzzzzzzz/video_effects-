# Velocity Veil — Android Studio Integration Handoff

`Velocity Veil` is a fullscreen directional blur. It averages a fixed number of samples along a configurable motion direction, creating softness that follows fast movement. This first registry version uses a host-supplied fallback direction; it does not require a motion-vector texture.

## Files

| File | Purpose |
|---|---|
| `effect.json` | Registry metadata and control definitions. |
| `velocity_veil.glsl` | GLSL ES 1.00 fragment shader. |
| `preview.webp` | Effect-picker preview. |

## Required shared inputs

| Input | Type | Integration requirement |
|---|---|---|
| `sTexture` | `samplerExternalOES` | Bind the video frame as `GL_TEXTURE_EXTERNAL_OES`. |
| `uTime` | `float` | Supply the shared animation time; it is not required for the current static blur path. |
| `uResolution` | `vec2` | Supply the output width and height in pixels. |
| `vTextureCoord` | `vec2` | Pass normalized coordinates through the existing fullscreen vertex shader. |

## Effect controls

| Uniform | Type | Default | Purpose |
|---|---|---:|---|
| `uAmount` | `float` | `16.0` | Maximum blur distance in pixels. |
| `uDirection` | `vec2` | `(1.0, 0.0)` | Normalized fallback direction; the shader normalizes it safely. |
| `uSamples` | `int` | `6` | Active sample count from 2 through 8. |
| `uPositionInfluence` | `float` | `1.0` | Contribution of positional movement to the fallback blur amount. |
| `uScaleInfluence` | `float` | `0.5` | Contribution of zoom/scaling to the fallback blur amount. |
| `uRotationInfluence` | `float` | `0.5` | Contribution of rotation to the fallback blur amount. |
| `uMix` | `float` | `1.0` | Blend between the original and softened frame. |

## Integration notes

The current shader computes `transformInfluence` as the average of the three influence controls and uses it to scale the directional sampling vector. The app should map its motion or transform UI into `uDirection` and `uAmount`. For an animated pan, update `uDirection` and `uAmount` per frame; for a simple clip-wide look, set them once.

A future renderer can replace the fallback with real motion vectors without changing the public metadata controls. If the app later adds a motion-vector texture, that texture should be introduced as an optional renderer capability rather than changing the existing `sTexture` contract.

The loop has a fixed upper bound for GLSL ES 1.00 portability. Lower-end devices can use a smaller `uSamples` value and a lower-resolution intermediate framebuffer. Avoid applying maximum blur to small text or faces when preserving sharpness is important.

## Validation

Test with `uAmount = 0` and confirm the frame is unchanged. Then test horizontal, vertical, and diagonal directions with `uSamples` set to 2, 6, and 8. Confirm that the renderer keeps the texture coordinates in the project’s established orientation.
