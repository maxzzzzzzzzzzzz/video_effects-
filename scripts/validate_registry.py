#!/usr/bin/env python3
"""Validate registry.json and every effect and transition definition.

Checks:
- registry.json, effect.json and transition.json files are valid JSON with required fields
- asset IDs are unique within their kind and match their folder name
- registry entries mirror the asset metadata (name, version, category, tags)
- referenced files (metadata, shader, previews) exist
- categories used are declared in registry "categories" / "transitionCategories"
- every parameter is a uniform in the shader, with sane min/max/default
- transition shaders declare the built-in two-input uniforms
- transition durations are ordered min <= default <= max
- versions are semver-like (X.Y.Z)

Usage: python3 scripts/validate_registry.py
Exits non-zero and prints all problems found if validation fails.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "registry.json"

REGISTRY_ENTRY_FIELDS = ["id", "name", "description", "version", "category", "tags", "preview", "metadata"]
TRANSITION_ENTRY_FIELDS = REGISTRY_ENTRY_FIELDS + ["defaultDurationMs"]
ASSET_FIELDS = [
    "id", "name", "description", "author", "license", "version",
    "category", "tags", "shader", "preview", "parameters", "compatibility",
]
TRANSITION_FIELDS = ASSET_FIELDS + ["duration"]
COMPAT_FIELDS = ["minRegistryVersion", "minAppVersion", "platforms", "shaderLanguage", "requiredExtensions"]
PARAM_FIELDS = ["id", "name", "description", "type", "default"]
PARAM_TYPES = {"float", "int", "bool", "vec2", "color"}
TRANSITION_UNIFORMS = ["sTextureFrom", "sTextureTo", "uProgress"]
OPTIONAL_PREVIEWS = ["previewFrom", "previewTo"]
SEMVER = re.compile(r"^\d+\.\d+\.\d+$")

errors: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def load_json(path: Path):
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        err(f"{path.relative_to(ROOT)}: file not found")
    except json.JSONDecodeError as e:
        err(f"{path.relative_to(ROOT)}: invalid JSON ({e})")
    return None


def require(obj: dict, fields: list[str], where: str) -> bool:
    missing = [f for f in fields if f not in obj]
    if missing:
        err(f"{where}: missing fields {missing}")
        return False
    return True


def has_uniform(shader_src: str, name: str) -> bool:
    return bool(re.search(rf"uniform\s+\w+\s+{re.escape(name)}\s*;", shader_src))


def validate_parameters(asset: dict, shader_src: str, where: str) -> None:
    for param in asset.get("parameters", []):
        pid = param.get("id", "<no id>")
        pwhere = f"{where} parameter '{pid}'"
        if not require(param, PARAM_FIELDS, pwhere):
            continue
        if param["type"] not in PARAM_TYPES:
            err(f"{pwhere}: unknown type '{param['type']}' (expected one of {sorted(PARAM_TYPES)})")
        if not has_uniform(shader_src, pid):
            err(f"{pwhere}: no matching 'uniform ... {pid};' found in shader")
        if param["type"] in ("float", "int", "bool"):
            if "min" not in param or "max" not in param:
                err(f"{pwhere}: numeric parameter needs 'min' and 'max'")
            elif not (param["min"] <= param["default"] <= param["max"]):
                err(f"{pwhere}: default {param['default']} outside range [{param['min']}, {param['max']}]")


def validate_duration(transition: dict, entry: dict, where: str, twhere: str) -> None:
    duration = transition.get("duration")
    if not isinstance(duration, dict):
        err(f"{twhere}: 'duration' must be an object with 'default', 'min' and 'max' (ms)")
        return
    if not require(duration, ["default", "min", "max"], f"{twhere} duration"):
        return
    if not (duration["min"] <= duration["default"] <= duration["max"]):
        err(f"{twhere} duration: default {duration['default']} outside range [{duration['min']}, {duration['max']}]")
    if entry.get("defaultDurationMs") != duration["default"]:
        err(f"{where}: 'defaultDurationMs' differs from {twhere} "
            f"({entry.get('defaultDurationMs')!r} != {duration['default']!r})")


def validate_asset(entry: dict, category_ids: set, where: str, kind: str) -> None:
    metadata_path = ROOT / entry["metadata"]
    asset = load_json(metadata_path)
    if asset is None:
        return
    awhere = str(metadata_path.relative_to(ROOT))
    fields = TRANSITION_FIELDS if kind == "transition" else ASSET_FIELDS
    if not require(asset, fields, awhere):
        return

    asset_dir = metadata_path.parent
    if asset["id"] != entry["id"]:
        err(f"{awhere}: id '{asset['id']}' does not match registry entry id '{entry['id']}'")
    if asset["id"] != asset_dir.name:
        err(f"{awhere}: id '{asset['id']}' does not match folder name '{asset_dir.name}'")
    if entry.get("kind", kind) != kind:
        err(f"{where}: kind '{entry['kind']}' should be '{kind}'")

    for field in ("name", "description", "version", "category", "tags"):
        if asset[field] != entry[field]:
            err(f"{where}: '{field}' differs from {awhere} ({entry[field]!r} != {asset[field]!r})")

    if not SEMVER.match(asset["version"]):
        err(f"{awhere}: version '{asset['version']}' is not semver (X.Y.Z)")
    if asset["category"] not in category_ids:
        err(f"{awhere}: category '{asset['category']}' not declared in registry "
            f"{'transitionCategories' if kind == 'transition' else 'categories'}")

    shader_path = asset_dir / asset["shader"]
    if not shader_path.is_file():
        err(f"{awhere}: shader '{asset['shader']}' not found")

    for field in ["preview"] + OPTIONAL_PREVIEWS:
        if field not in asset:
            if field in entry:
                err(f"{where}: '{field}' is set but missing from {awhere}")
            continue
        preview_path = asset_dir / asset[field]
        if not preview_path.is_file():
            err(f"{awhere}: {field} '{asset[field]}' not found")
        if field not in entry:
            err(f"{where}: missing '{field}' declared in {awhere}")
        elif (ROOT / entry[field]) != preview_path:
            err(f"{where}: {field} path '{entry[field]}' does not point at "
                f"'{preview_path.relative_to(ROOT)}'")

    require(asset["compatibility"], COMPAT_FIELDS, f"{awhere} compatibility")

    if kind == "transition":
        validate_duration(asset, entry, where, awhere)

    if shader_path.is_file():
        shader_src = shader_path.read_text()
        if kind == "transition":
            for uniform in TRANSITION_UNIFORMS:
                if not has_uniform(shader_src, uniform):
                    err(f"{awhere}: transition shader must declare 'uniform ... {uniform};'")
        validate_parameters(asset, shader_src, awhere)


def validate_section(registry: dict, key: str, categories_key: str, kind: str, entry_fields: list[str]) -> int:
    category_ids = {c["id"] for c in registry.get(categories_key, [])}
    seen_ids: set = set()
    for i, entry in enumerate(registry.get(key, [])):
        where = f"registry.json {key}[{i}]"
        if not require(entry, entry_fields, where):
            continue
        if entry["id"] in seen_ids:
            err(f"{where}: duplicate {kind} id '{entry['id']}'")
        seen_ids.add(entry["id"])
        validate_asset(entry, category_ids, where, kind)
    return len(seen_ids)


def main() -> int:
    registry = load_json(REGISTRY)
    if registry is None:
        print("\n".join(errors))
        return 1

    require(
        registry,
        ["registryVersion", "revision", "updatedAt", "categories", "transitionCategories", "effects", "transitions"],
        "registry.json",
    )

    effect_count = validate_section(registry, "effects", "categories", "effect", REGISTRY_ENTRY_FIELDS)
    transition_count = validate_section(
        registry, "transitions", "transitionCategories", "transition", TRANSITION_ENTRY_FIELDS
    )

    if errors:
        print(f"FAILED: {len(errors)} problem(s) found:")
        for e in errors:
            print(f"  - {e}")
        return 1

    print(f"OK: registry, {effect_count} effect(s) and {transition_count} transition(s) are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
