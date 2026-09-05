#!/usr/bin/env python3
"""Resolve only checksum-approved assets. Never download during gameplay."""
from __future__ import annotations
import hashlib
import json
import os
from pathlib import Path
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
MAX_ARCHIVE_BYTES = 150 * 1024 * 1024
MAX_MEMBER_BYTES = 4 * 1024 * 1024


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def prepare() -> None:
    manifest = json.loads((ROOT / "assets/manifest.json").read_text())
    for pack in manifest["packs"]:
        destination = ROOT / "assets/vendor" / pack["id"]
        expected = dict(pack["files"])
        expected["LICENSE.txt"] = pack["license_sha256"]
        if all((destination / name).is_file() and digest((destination / name).read_bytes()) == checksum for name, checksum in expected.items()):
            print(f"ASSETS_OK {pack['id']} (verified existing files)")
            continue
        archive = Path(os.environ.get("ASSET_ARCHIVE", ROOT / ".cache" / f"{pack['id']}.zip"))
        if not archive.exists():
            archive.parent.mkdir(parents=True, exist_ok=True)
            with urllib.request.urlopen(pack["download"], timeout=60) as response:
                data = response.read(MAX_ARCHIVE_BYTES + 1)
            if len(data) > MAX_ARCHIVE_BYTES or digest(data) != pack["sha256"]:
                raise RuntimeError("Asset archive size/checksum mismatch; refusing changed upstream content")
            archive.write_bytes(data)
        if archive.stat().st_size > MAX_ARCHIVE_BYTES or digest(archive.read_bytes()) != pack["sha256"]:
            raise RuntimeError("Cached asset archive checksum mismatch")
        destination.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(archive) as source:
            for name, checksum in expected.items():
                if Path(name).name != name:
                    raise RuntimeError("Manifest file names must be leaves")
                member = pack["license_member"] if name == "LICENSE.txt" else pack["member_prefix"] + name
                if source.getinfo(member).file_size > MAX_MEMBER_BYTES:
                    raise RuntimeError("Asset member exceeds budget")
                data = source.read(member)
                if digest(data) != checksum:
                    raise RuntimeError(f"Member checksum mismatch: {name}")
                (destination / name).write_bytes(data)
        print(f"ASSETS_OK {pack['id']} ({len(pack['files'])} models + license)")


if __name__ == "__main__":
    prepare()
