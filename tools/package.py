#!/usr/bin/env python3
"""Package standalone release clients on Linux; no publishing or signing secrets."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import platform
import plistlib
import shutil
import stat
import struct
import subprocess
import sys
import tarfile
import zipfile

import dev

ROOT = dev.ROOT
BUILD = ROOT / "build"
DISTRIBUTION = ROOT / "tools/distribution"
MACHO_X86_64 = 0x01000007
MACHO_ARM64 = 0x0100000C


def sha256(path: Path) -> str:
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def source_sha() -> str:
    result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True, capture_output=True)
    if result.returncode:
        raise RuntimeError("Package from a Git checkout so the source SHA is unambiguous")
    dirty = subprocess.check_output(["git", "status", "--porcelain", "--untracked-files=normal"], cwd=ROOT, text=True)
    if dirty.strip():
        raise RuntimeError("Refusing to label a dirty working tree as a tested commit. Commit changes first.")
    return result.stdout.strip()


def copy_file(source: Path, destination: Path, executable: bool = False) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, destination)
    destination.chmod(0o755 if executable else 0o644)


def verify_macos(bundle: Path) -> dict:
    """Static checks only: plist, Universal 2 slices, mode, PCK and signing envelope."""
    info = plistlib.loads((bundle / "Contents/Info.plist").read_bytes())
    name = info["CFBundleExecutable"]
    if PurePosixPath(name).name != name:
        raise RuntimeError("Executable name is not a leaf")
    executable = bundle / "Contents/MacOS" / name
    if not executable.stat().st_mode & stat.S_IXUSR:
        raise RuntimeError("macOS executable permission missing")
    with executable.open("rb") as source:
        header = source.read(8)
        magic, count = struct.unpack(">II", header)
        if magic != 0xCAFEBABE or count != 2:
            raise RuntimeError("Expected a Universal 2 Mach-O with exactly two slices")
        slices = [struct.unpack(">IIIII", source.read(20)) for _ in range(count)]
    if {value[0] for value in slices} != {MACHO_X86_64, MACHO_ARM64}:
        raise RuntimeError("Both Intel and Apple Silicon slices are required")
    if any(offset + size > executable.stat().st_size for _, _, offset, size, _ in slices):
        raise RuntimeError("Truncated Mach-O slice")
    pcks = list((bundle / "Contents/Resources").glob("*.pck"))
    if len(pcks) != 1 or pcks[0].stat().st_size == 0:
        raise RuntimeError("Expected exactly one nonempty game PCK")
    if not (bundle / "Contents/_CodeSignature/CodeResources").is_file():
        raise RuntimeError("Built-in ad-hoc bundle signature was not produced")
    if info.get("CFBundleIdentifier") != "io.github.t-damer.guests":
        raise RuntimeError("Unexpected application identifier")
    return {"architectures": ["x86_64", "arm64"], "bundle_executable": name,
            "static_bundle_check": "PASS", "native_macos_launch": "NOT RUN during Linux packaging",
            "signing": "ad-hoc; not Apple Developer ID; not notarized"}


def extract_app(archive_path: Path, destination: Path) -> Path:
    """Keep executable bits, reject unsafe members; normalize only the outer app name."""
    with zipfile.ZipFile(archive_path) as archive:
        roots = {PurePosixPath(i.filename).parts[0] for i in archive.infolist()
                 if PurePosixPath(i.filename).parts and PurePosixPath(i.filename).parts[0].endswith(".app")}
        if len(roots) != 1:
            raise RuntimeError(f"Expected one exported .app bundle, found {roots}")
        app_root = roots.pop()
        for member in archive.infolist():
            path = PurePosixPath(member.filename)
            if path.is_absolute() or ".." in path.parts:
                raise RuntimeError("Unsafe path in macOS export")
            if not path.parts or path.parts[0] != app_root:
                continue
            mode = member.external_attr >> 16
            if stat.S_ISLNK(mode):
                raise RuntimeError("Unexpected symlink: this export does not use frameworks")
            output = destination / "GUESTS.app" / Path(*path.parts[1:])
            if member.is_dir():
                output.mkdir(parents=True, exist_ok=True)
                output.chmod(0o755)
            else:
                output.parent.mkdir(parents=True, exist_ok=True)
                with archive.open(member) as source, output.open("wb") as sink:
                    shutil.copyfileobj(source, sink)
                output.chmod(0o755 if mode & 0o111 else 0o644)
    return destination / "GUESTS.app"


def finish_package(directory: Path, target: str, commit: str, checks: dict) -> None:
    copy_file(DISTRIBUTION / f"README-{target}.txt", directory / "README.txt")
    copy_file(ROOT / "NOTICE.md", directory / "NOTICE.md")
    copy_file(ROOT / "assets/vendor/kenney-furniture/LICENSE.txt", directory / "KENNEY-LICENSE.txt")
    copy_file(BUILD / "GODOT-LICENSES.txt", directory / "GODOT-LICENSES.txt")
    receipt = {"project": "GUESTS", "version": "0.1.0-prototype", "source_commit": commit,
               "engine": dev.VERSION, "build_host": platform.platform(), "target": target,
               "configuration": "release", "checks": checks,
               "limitations": ["solo prototype, not playable coop", "audio is placeholder",
                               "known audio-object shutdown warnings", "not a performance or fun assessment"]}
    (directory / "BUILD_INFO.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2) + "\n")
    sums = [f"{sha256(p)}  {p.relative_to(directory).as_posix()}" for p in sorted(directory.rglob("*")) if p.is_file()]
    (directory / "SHA256SUMS").write_text("\n".join(sums) + "\n")


def package_linux(commit: str) -> Path:
    dev.install_templates()
    directory = BUILD / "GUESTS-linux-x86_64"
    if directory.exists():
        shutil.rmtree(directory)
    directory.mkdir()
    executable = directory / "guests.x86_64"
    dev.run_engine(["--headless", "--export-release", "Linux", str(executable)], "package-linux-export.log", timeout=240)
    executable.chmod(0o755)
    with executable.open("rb") as source:
        header = source.read(20)
    if header[:6] != b"\x7fELF\x02\x01" or struct.unpack_from("<H", header, 18)[0] != 62:
        raise RuntimeError("Expected x86_64 ELF client")
    copy_file(DISTRIBUTION / "start.sh", directory / "start.sh", executable=True)
    (directory / "guests.sh").unlink(missing_ok=True)
    checks = {"elf_x86_64": "PASS", "native_linux_launch": "NOT RUN on this host"}
    if platform.system() == "Linux" and platform.machine() == "x86_64":
        # Use the final launcher from a different cwd. This checks path handling too.
        result = subprocess.run(["sh", str(directory / "start.sh"), "--headless", "--quit-after", "45"],
                                cwd=BUILD.parent.parent, capture_output=True, text=True, timeout=45)
        log = result.stdout + result.stderr
        (dev.ARTIFACTS / "package-linux-smoke.log").write_text(log)
        if result.returncode or any(token in log for token in dev.ERROR_TOKENS):
            raise RuntimeError(f"Packaged Linux launcher failed:\n{log}")
        checks["native_linux_launch"] = "PASS (headless, packaged launcher, different cwd)"
    finish_package(directory, "linux", commit, checks)
    output = BUILD / "GUESTS-linux-x86_64.tar.gz"
    with tarfile.open(output, "w:gz") as archive:
        archive.add(directory, arcname=directory.name)
    return output


def install_macos_template() -> None:
    # Reuse the verified official archive downloader; only extract the macOS archive.
    if platform.system() == "Darwin":
        base = Path.home() / "Library/Application Support/Godot/export_templates"
    elif platform.system() == "Windows":
        base = Path(os.environ["APPDATA"]) / "Godot/export_templates"
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "godot/export_templates"
    destination = base / f"{dev.VERSION}.stable"
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(dev.archive_file(f"{dev.PREFIX}_export_templates.tpz")) as archive:
        (destination / "macos.zip").write_bytes(archive.read("templates/macos.zip"))
        (destination / "version.txt").write_bytes(archive.read("templates/version.txt"))


def package_macos(commit: str) -> Path:
    install_macos_template()
    raw_export = BUILD / "macos-export.zip"
    dev.run_engine(["--headless", "--export-release", "macOS", str(raw_export)], "package-macos-export.log", timeout=240)
    directory = BUILD / "macos-package"
    if directory.exists():
        shutil.rmtree(directory)
    directory.mkdir()
    bundle = extract_app(raw_export, directory)
    checks = verify_macos(bundle)
    finish_package(directory, "macos", commit, checks)
    output = BUILD / "GUESTS-macOS.zip"
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted(directory.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(directory).as_posix())
    return output


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", choices=["linux", "macos", "all"])
    args = parser.parse_args()
    commit = source_sha()
    BUILD.mkdir(exist_ok=True)
    (BUILD / ".gdignore").touch()
    dev.prepare()
    dev.run_engine(["--headless", "--script", "res://tools/export_notices.gd"], "package-notices.log", "GUESTS_NOTICES_OK")
    outputs = []
    if args.target in {"linux", "all"}:
        outputs.append(package_linux(commit))
    if args.target in {"macos", "all"}:
        outputs.append(package_macos(commit))
    for path in outputs:
        checksum = sha256(path)
        path.with_name(path.name + ".sha256").write_text(f"{checksum}  {path.name}\n")
        print(f"GUESTS_PACKAGE_OK {path.name} sha256={checksum}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        print(f"PACKAGE_FAILED: {error}", file=sys.stderr)
        sys.exit(1)
