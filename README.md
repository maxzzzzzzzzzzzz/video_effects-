# video_effects-
Official video effects for video editor app

## Effects

| ID | Name | Category | Description |
|---|---|---|---|
| `vhs` | VHS | retro | Horizontal jitter, RGB split and scanlines |
| `glitch` | Glitch | glitch | Block displacement, vertical roll and RGB split |
| `film_grain` | Film Grain | retro | Animated grain, warm tone and vignette |
| `crt` | CRT | retro | Barrel curvature, phosphor mask, scanlines, flicker |
| `pixelate` | Pixelate | stylize | Mosaic pixelation with optional posterization |
| `duotone` | Duotone | color | Luminance mapped onto a two-color gradient |

## Transitions

| ID | Name | Category | Description |
|---|---|---|---|
| `dissolve` | Dissolve | dissolve | Cross dissolve, from a clean fade to a grainy film burn |
| `wipe` | Wipe | wipe | Directional wipe at any angle with a feathered edge |

Effects and transitions live in the **same registry and the same URL** — `registry.json` carries them in two separate arrays (`effects` and `transitions`), each entry tagged with `kind`, so the app fetches one file and shows them in separate pickers. `registryVersion` is `2` since transitions were added; an app built against version 1 can keep reading `effects` and ignore the rest.

## Structure

- `registry.json` — top-level index the app fetches to discover effects and transitions. Contains `categories`, `transitionCategories`, and one entry per asset with `id`, `kind`, `name`, `description`, `version`, `category`, `tags`, `preview`, a `metadata` path to the asset's full definition, and `sha256` checksums of its files. Transition entries additionally carry `previewFrom`, `previewTo` and `defaultDurationMs`.
  - `revision` / `updatedAt` are stamped automatically by CI (`.github/workflows/stamp-revision.yml`) with the commit hash and timestamp on every push to `main` — the app can compare `revision` with a cached value to detect registry updates without any manual version bump. The same workflow refreshes all `sha256` checksums.
- `effects/<id>/effect.json` — full effect metadata (see schema below).
- `effects/<id>/*.glsl` — the effect's fragment shader.
- `effects/<id>/preview.webp` — preview image shown in the effect picker.
- `transitions/<id>/transition.json` — full transition metadata (see schema below).
- `transitions/<id>/*.glsl` — the transition's fragment shader.
- `transitions/<id>/preview.webp` — preview image shown in the transition picker, plus optional `preview_from.webp` / `preview_to.webp` showing the two clips being blended.
- `scripts/validate_registry.py` — validates the registry and all effects and transitions; runs in CI on every PR and push to `main` (`.github/workflows/validate.yml`).
- `scripts/update_checksums.py` — recomputes the `sha256` checksums in `registry.json`; run automatically by CI.

## Integrity

Each registry entry carries `sha256` checksums for the asset's `metadata`, `shader` and preview files (`preview`, and `previewFrom` / `previewTo` where present), refreshed automatically on every push to `main`. The app should verify downloaded files against these hashes before using them.

## Releases

Pushing a tag like `v1.2.0` triggers `.github/workflows/release.yml`, which validates the registry, packages each effect as `dist/<id>.zip` and each transition as `dist/transition-<id>.zip`, and publishes a GitHub Release with the zips, `registry.json` and a `SHA256SUMS.txt` — useful if the app prefers atomic, versioned downloads over raw file fetching.

## effect.json schema

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique effect ID (matches folder name and registry entry). |
| `name` | string | Display name. |
| `description` | string | Short description shown in the UI. |
| `author` | string | Effect author. |
| `license` | string | License identifier (e.g. `Edactor` — see the LICENSE file). |
| `version` | string | Semantic version of the effect (`X.Y.Z`). |
| `category` | string | Category ID; must be declared in `registry.json` `categories`. |
| `tags` | array | Free-form search/filter tags. |
| `shader` | string | Fragment shader filename, relative to the effect folder. |
| `preview` | string | Preview image filename, relative to the effect folder. |
| `parameters` | array | User-adjustable shader uniforms (see below). |
| `compatibility` | object | Requirements for running the effect (see below). |

### parameters[]

| Field | Type | Description |
|---|---|---|
| `id` | string | Uniform name in the shader (e.g. `uIntensity`). |
| `name` | string | Display name for the slider/control. |
| `description` | string | Tooltip/help text. |
| `type` | string | Value type (`float`, `int`, `bool`, `vec2`, `color`). |
| `min` / `max` | number | Allowed range (required for numeric types). |
| `default` | number/array | Initial value (array of 3 floats for `color`). |

Built-in uniforms provided by the app at render time (not listed as parameters): `sTexture`, `uTime`, `uResolution`.

### compatibility

| Field | Type | Description |
|---|---|---|
| `minRegistryVersion` | int | Minimum registry schema version. |
| `minAppVersion` | string | Minimum app version that can run the effect. |
| `platforms` | array | Supported platforms (e.g. `android`). |
| `shaderLanguage` | string | Shader dialect (e.g. `glsl-es-100`). |
| `requiredExtensions` | array | GL extensions the shader needs. |

## transition.json schema

Same fields as `effect.json`, with these differences:

| Field | Type | Description |
|---|---|---|
| `category` | string | Category ID; must be declared in `registry.json` `transitionCategories`. |
| `previewFrom` | string | Optional. Still of the outgoing clip, for pickers that show both sides. |
| `previewTo` | string | Optional. Still of the incoming clip. |
| `duration` | object | `{ "default", "min", "max" }` in milliseconds; `default` must match `defaultDurationMs` in the registry entry. |

A transition blends two clips instead of filtering one, so the app supplies different built-in uniforms (not listed as parameters): `sTextureFrom`, `sTextureTo`, `uProgress` (0 → 1 across the transition), `uTime`, `uResolution`. The first three are required and CI rejects a transition shader that does not declare them. Everything else — `parameters`, `compatibility`, checksums, versioning — works exactly as it does for effects.

## Adding a new effect or transition

1. Create `effects/<id>/` with `effect.json`, the shader and a `preview.webp` — or `transitions/<id>/` with `transition.json`, the shader and its previews.
2. Add a matching entry to `registry.json` under `effects` or `transitions` (leave `sha256` as `{}` — CI fills it in).
3. Run `python3 scripts/validate_registry.py` locally.
4. Open a PR — CI validates everything; after merge to `main`, CI stamps `revision` and checksums automatically.
