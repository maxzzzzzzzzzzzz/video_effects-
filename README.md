# video_effects-
Official video effects for video editor app

## Structure

- `registry.json` — top-level index the app fetches to discover effects. Each entry has `id`, `name`, `description`, `version`, `preview`, and a `metadata` path to the effect's full definition.
- `effects/<id>/effect.json` — full effect metadata (see schema below).
- `effects/<id>/*.glsl` — the effect's fragment shader.
- `effects/<id>/preview.webp` — preview image shown in the effect picker.

## effect.json schema

| Field | Type | Description |
|---|---|---|
| `id` | string | Unique effect ID (matches folder name and registry entry). |
| `name` | string | Display name. |
| `description` | string | Short description shown in the UI. |
| `author` | string | Effect author. |
| `license` | string | SPDX license identifier (e.g. `MIT`). |
| `version` | string | Semantic version of the effect. |
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
| `min` / `max` | number | Allowed range. |
| `default` | number | Initial value. |

Built-in uniforms provided by the app at render time (not listed as parameters): `sTexture`, `uTime`, `uResolution`.

### compatibility

| Field | Type | Description |
|---|---|---|
| `minRegistryVersion` | int | Minimum registry schema version. |
| `minAppVersion` | string | Minimum app version that can run the effect. |
| `platforms` | array | Supported platforms (e.g. `android`). |
| `shaderLanguage` | string | Shader dialect (e.g. `glsl-es-100`). |
| `requiredExtensions` | array | GL extensions the shader needs. |
