#!/usr/bin/env python3
"""Recompute SHA-256 checksums for every effect's and transition's files and
write them into each registry.json entry under "sha256".

Usage: python3 scripts/update_checksums.py
Run from the repository root. CI runs this automatically on every push
to main (see .github/workflows/stamp-revision.yml).
"""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REGISTRY = ROOT / "registry.json"
PREVIEW_FIELDS = ["preview", "previewFrom", "previewTo"]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def update_section(registry: dict, key: str) -> int:
    for entry in registry.get(key, []):
        metadata_path = ROOT / entry["metadata"]
        asset = json.loads(metadata_path.read_text())
        asset_dir = metadata_path.parent

        checksums = {
            "metadata": sha256(metadata_path),
            "shader": sha256(asset_dir / asset["shader"]),
        }
        for field in PREVIEW_FIELDS:
            if field in asset:
                checksums[field] = sha256(asset_dir / asset[field])
        entry["sha256"] = checksums
    return len(registry.get(key, []))


def main() -> int:
    registry = json.loads(REGISTRY.read_text())

    effects = update_section(registry, "effects")
    transitions = update_section(registry, "transitions")

    REGISTRY.write_text(json.dumps(registry, indent=2) + "\n")
    print(f"Updated checksums for {effects} effects and {transitions} transitions.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
