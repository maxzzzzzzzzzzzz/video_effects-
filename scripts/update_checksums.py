#!/usr/bin/env python3
"""Recompute SHA-256 checksums for every effect's files and write them
into each registry.json entry under "sha256".

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


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> int:
    registry = json.loads(REGISTRY.read_text())

    for entry in registry["effects"]:
        metadata_path = ROOT / entry["metadata"]
        effect = json.loads(metadata_path.read_text())
        effect_dir = metadata_path.parent

        entry["sha256"] = {
            "metadata": sha256(metadata_path),
            "shader": sha256(effect_dir / effect["shader"]),
            "preview": sha256(effect_dir / effect["preview"]),
        }

    REGISTRY.write_text(json.dumps(registry, indent=2) + "\n")
    print(f"Updated checksums for {len(registry['effects'])} effects.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
