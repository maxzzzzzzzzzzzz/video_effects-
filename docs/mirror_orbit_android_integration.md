# Mirror Orbit — Android Studio Integration Handoff

`Mirror Orbit` is a fullscreen radial-reflection effect. It converts normalized texture coordinates into polar coordinates around `uCenter`, mirrors alternating sectors, and samples the source texture to create a repeating kaleidoscopic pattern.

## Files

| File | Purpose |
|---|---|
| `effect.json` | Registry metadata and control definitions. |
| `mirror_orbit.glsl` | GLSL ES 1.00 fragment shader. |
| `preview.webp` | Effect-picker preview. |

## Required shared inputs

| Input | Type | Integration requirement |
|---|---|---|
| `sTexture` | `samplerExternalOES` | Bind the decoded or camera frame as `GL_TEXTURE_EXTERNAL_OES`. |
| `uTime` | `float` | Supply the app’s current time. It is part of the shared contract and may be optimized out when unused. |
| `uResolution` | `vec2` | Supply the output width and height in pixels. |
| `vTextureCoord` | `vec2` | Pass normalized texture coordinates from the existing fullscreen vertex shader. |

## Effect controls

| Uniform | Type | Default | Purpose |
|---|---|---:|---|
| `uSegments` | `float` | `8.0` | Number of repeated radial sectors. |
| `uCenter` | `vec2` | `(0.5, 0.5)` | Symmetry point in normalized coordinates. |
| `uRotation` | `float` | `0.0` | Sector rotation in radians; animate this for orbital motion. |
| `uZoom` | `float` | `1.0` | Source-image scale inside each sector. |
| `uMirrorMode` | `float` | `1.0` | Alternates mirrored and non-mirrored sectors when above `0.5`. |
| `uFeather` | `float` | `0.18` | Softens the sector seams. |
| `uMix` | `float` | `1.0` | Blends the pattern with the original frame. |

## Integration notes

The host should set `uResolution` to the actual render-target dimensions, not the device’s logical density-independent size. The shader applies an aspect correction before its polar transform so circular patterns remain visually circular on non-square video frames.

For a static look, keep `uRotation` fixed. For a slow orbit, advance `uRotation` from the app’s animation clock, for example `rotation = baseRotation + timeSeconds * rotationSpeed`. The current shader performs one transformed source lookup plus the original-frame lookup, so it is materially lighter than a multi-pass kaleidoscope implementation.

The app should correct any camera/video vertical flip in the shared vertex texture matrix. Do not add a one-off flip to this shader, because that would make the effect behave differently from the other registry effects.

## Validation

The effect must be loaded from `registry.json`, linked with the app’s existing fullscreen vertex shader, and rendered with the external OES texture target. Start with the `effect.json` defaults, then test `uSegments` at 4, 8, and 16 and `uMix` at 0 and 1 to verify both the unmodified and transformed paths.
