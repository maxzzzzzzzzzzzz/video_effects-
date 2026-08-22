# Impact Tremor — Android Studio Integration Handoff

`Impact Tremor` is a time-driven fullscreen camera-shake treatment. It generates deterministic pseudo-random translation, rotation, and scale offsets and shapes them with an attack-and-decay envelope so the movement feels like a short impact rather than continuous noise.

## Files

| File | Purpose |
|---|---|
| `effect.json` | Registry metadata and control definitions. |
| `impact_tremor.glsl` | GLSL ES 1.00 fragment shader. |
| `preview.webp` | Effect-picker preview. |

## Required shared inputs

| Input | Type | Integration requirement |
|---|---|---|
| `sTexture` | `samplerExternalOES` | Bind the video frame as `GL_TEXTURE_EXTERNAL_OES`. |
| `uTime` | `float` | Supply a monotonically increasing time in seconds. This drives the tremor envelope. |
| `uResolution` | `vec2` | Supply the output width and height in pixels. |
| `vTextureCoord` | `vec2` | Pass normalized coordinates from the existing fullscreen vertex shader. |

## Effect controls

| Uniform | Type | Default | Purpose |
|---|---|---:|---|
| `uAmplitude` | `float` | `8.0` | Maximum translation in pixels. |
| `uFrequency` | `float` | `2.5` | Envelope repetitions per second. |
| `uRotationAmount` | `float` | `0.04` | Maximum rotation in radians. |
| `uScaleAmount` | `float` | `0.05` | Maximum scale variation. |
| `uDecay` | `float` | `4.0` | How quickly the movement settles. |
| `uSeed` | `float` | `7.0` | Deterministically changes the movement pattern. |
| `uMix` | `float` | `1.0` | Blends the displaced frame with the original. |

## Integration notes

The host should advance `uTime` in seconds and reset it to a chosen beat or impact start time when a synced hit begins. For a one-shot impact, the application can reset the effect clock at the impact and allow the shader envelope to decay. For a continuously running clip treatment, let `uTime` run normally.

The shader uses a fixed pseudo-random function rather than a device-dependent random source. The same time, frequency, and seed therefore produce a repeatable pattern, which is useful for preview/export consistency. The UV sample is clamped near the frame edges to avoid invalid samples after the simulated camera movement.

Keep the default amplitude modest. Large offsets can expose repeated edge pixels and can make subtitles difficult to read. If the app has a beat-sync system, it can animate `uAmplitude` and `uDecay` per event without changing the registry contract.

## Validation

Render with `uAmplitude = 0` and confirm the source frame is unchanged. Then render at the default settings and confirm that the movement settles over each cycle. Test both preview and export paths with identical `uTime` units so the effect does not play at different speeds in the two pipelines.
