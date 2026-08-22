#!/usr/bin/env python3
"""Validate registry.json and every effect definition.

Checks:
- registry.json and all effect.json files are valid JSON with required fields
- effect IDs are unique and match their folder name
- registry entries mirror the effect metadata (name, version, category, tags)
- referenced files (metadata, shader, preview) exist
- categories used by effects are declared in registry "categories"
- every parameter is a uniform in the shader, with sane min/max/default
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
EFFECT_FIELDS = [
    "id", "name", "description", "author", "license", "version",
    "category", "tags", "shader", "preview", "parameters", "compatibility",
]
COMPAT_FIELDS = ["minRegistryVersion", "minAppVersion", "platforms", "shaderLanguage", "requiredExtensions"]
PARAM_FIELDS = ["id", "name", "description", "type", "default"]
PARAM_TYPES = {"float", "int", "bool", "vec2", "color"}
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


def validate_parameters(effect: dict, shader_src: str, where: str) -> None:
    for param in effect.get("parameters", []):
        pid = param.get("id", "<no id>")
        pwhere = f"{where} parameter '{pid}'"
        if not require(param, PARAM_FIELDS, pwhere):
            continue
        if param["type"] not in PARAM_TYPES:
            err(f"{pwhere}: unknown type '{param['type']}' (expected one of {sorted(PARAM_TYPES)})")
        if not re.search(rf"uniform\s+\w+\s+{re.escape(pid)}\s*;", shader_src):
            err(f"{pwhere}: no matching 'uniform ... {pid};' found in shader")
        if param["type"] in ("float", "int", "bool"):
            if "min" not in param or "max" not in param:
                err(f"{pwhere}: numeric parameter needs 'min' and 'max'")
            elif not (param["min"] <= param["default"] <= param["max"]):
                err(f"{pwhere}: default {param['default']} outside range [{param['min']}, {param['max']}]")


def validate_effect(entry: dict, category_ids: set, where: str) -> None:
    metadata_path = ROOT / entry["metadata"]
    effect = load_json(metadata_path)
    if effect is None:
        return
    ewhere = str(metadata_path.relative_to(ROOT))
    if not require(effect, EFFECT_FIELDS, ewhere):
        return

    effect_dir = metadata_path.parent
    if effect["id"] != entry["id"]:
        err(f"{ewhere}: id '{effect['id']}' does not match registry entry id '{entry['id']}'")
    if effect["id"] != effect_dir.name:
        err(f"{ewhere}: id '{effect['id']}' does not match folder name '{effect_dir.name}'")

    for field in ("name", "description", "version", "category", "tags"):
        if effect[field] != entry[field]:
            err(f"{where}: '{field}' differs from {ewhere} ({entry[field]!r} != {effect[field]!r})")

    if not SEMVER.match(effect["version"]):
        err(f"{ewhere}: version '{effect['version']}' is not semver (X.Y.Z)")
    if effect["category"] not in category_ids:
        err(f"{ewhere}: category '{effect['category']}' not declared in registry categories")

    shader_path = effect_dir / effect["shader"]
    preview_path = effect_dir / effect["preview"]
    if not shader_path.is_file():
        err(f"{ewhere}: shader '{effect['shader']}' not found")
    if not preview_path.is_file():
        err(f"{ewhere}: preview '{effect['preview']}' not found")
    if (ROOT / entry["preview"]) != preview_path:
        err(f"{where}: preview path '{entry['preview']}' does not point at '{preview_path.relative_to(ROOT)}'")

    require(effect["compatibility"], COMPAT_FIELDS, f"{ewhere} compatibility")

    if shader_path.is_file():
        validate_parameters(effect, shader_path.read_text(), ewhere)


def main() -> int:
    registry = load_json(REGISTRY)
    if registry is None:
        print("\n".join(errors))
        return 1

    require(registry, ["registryVersion", "revision", "updatedAt", "categories", "effects"], "registry.json")

    category_ids = {c["id"] for c in registry.get("categories", [])}
    seen_ids: set = set()
    for i, entry in enumerate(registry.get("effects", [])):
        where = f"registry.json effects[{i}]"
        if not require(entry, REGISTRY_ENTRY_FIELDS, where):
            continue
        if entry["id"] in seen_ids:
            err(f"{where}: duplicate effect id '{entry['id']}'")
        seen_ids.add(entry["id"])
        validate_effect(entry, category_ids, where)

    if errors:
        print(f"FAILED: {len(errors)} problem(s) found:")
        for e in errors:
            print(f"  - {e}")
        return 1

    print(f"OK: registry and {len(seen_ids)} effect(s) are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
