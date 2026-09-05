#!/usr/bin/env python3
"""One development entry point. Python 3.11+, standard library only."""
from __future__ import annotations
import argparse
import hashlib
import os
from pathlib import Path
import platform
import shutil
import socket
import subprocess
import sys
import time
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = (ROOT / ".godot-version").read_text().strip()
TOOLS = ROOT / ".tools/godot"
CACHE = ROOT / ".cache"
ARTIFACTS = ROOT / "artifacts"
RELEASE = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable"
PREFIX = f"Godot_v{VERSION}-stable"
ERROR_TOKENS = ("SCRIPT ERROR:", "ERROR:", "GUESTS_NET_FAILED", "GUESTS_RULES_FAILED")


def archive_file(name: str) -> Path:
    CACHE.mkdir(exist_ok=True)
    sums_path = CACHE / f"{VERSION}-SHA512-SUMS.txt"
    if not sums_path.exists():
        with urllib.request.urlopen(f"{RELEASE}/SHA512-SUMS.txt", timeout=60) as response:
            sums_path.write_bytes(response.read())
    sums = {parts[-1].lstrip("*"): parts[0] for line in sums_path.read_text().splitlines() if len(parts := line.split()) >= 2}
    if name not in sums:
        raise RuntimeError(f"Official checksum manifest has no {name}")
    target = CACHE / name
    if not target.exists():
        temporary = target.with_suffix(target.suffix + ".tmp")
        with urllib.request.urlopen(f"{RELEASE}/{name}", timeout=120) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output)
        temporary.replace(target)
    with target.open("rb") as source:
        checksum = hashlib.file_digest(source, "sha512").hexdigest()
    if checksum != sums[name]:
        raise RuntimeError(f"Checksum mismatch for {target}; remove the corrupted cache file and retry")
    return target


def install_engine() -> None:
    system = platform.system()
    if system == "Linux":
        architecture = "arm64" if platform.machine() in {"aarch64", "arm64"} else "x86_64"
        name = f"{PREFIX}_linux.{architecture}.zip"
    elif system == "Darwin":
        name = f"{PREFIX}_macos.universal.zip"
    elif system == "Windows":
        name = f"{PREFIX}_win64.exe.zip"
    else:
        raise RuntimeError(f"Unsupported development OS: {system}")
    with zipfile.ZipFile(archive_file(name)) as archive:
        for member in archive.namelist():
            if Path(member).is_absolute() or ".." in Path(member).parts:
                raise RuntimeError("Unsafe toolchain archive member")
        archive.extractall(TOOLS)
    for candidate in TOOLS.rglob("*"):
        if candidate.is_file() and (candidate.name.startswith(PREFIX) or candidate.name == "Godot"):
            candidate.chmod(candidate.stat().st_mode | 0o111)
    print(f"TOOLCHAIN_OK {engine()}")


def engine() -> str:
    override = os.environ.get("GODOT_BIN")
    if override:
        candidate = Path(override).expanduser().resolve()
    else:
        choices = list(TOOLS.glob(f"{PREFIX}_linux.*")) + list(TOOLS.glob(f"{PREFIX}_win64.exe")) + [TOOLS / "Godot.app/Contents/MacOS/Godot"]
        candidate = next((path for path in choices if path.is_file()), None)
        if candidate is None:
            found = shutil.which("godot") or shutil.which("godot4")
            if found is None:
                raise RuntimeError("Run python3 tools/dev.py setup, or set GODOT_BIN to the pinned editor executable")
            candidate = Path(found)
    actual = subprocess.check_output([str(candidate), "--version"], text=True).strip()
    if not actual.startswith(f"{VERSION}.stable."):
        raise RuntimeError(f"Godot version mismatch: expected {VERSION}.stable, got {actual}")
    return str(candidate)


def run_engine(arguments: list[str], log_name: str, marker: str | None = None, timeout: int = 90) -> str:
    ARTIFACTS.mkdir(exist_ok=True)
    command = [engine(), "--path", str(ROOT), *arguments]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True, timeout=timeout)
    text = result.stdout + result.stderr
    (ARTIFACTS / log_name).write_text(text, encoding="utf-8")
    print(text, end="")
    if result.returncode or any(token in text for token in ERROR_TOKENS) or (marker and marker not in text):
        raise RuntimeError(f"Godot check failed: {log_name} (exit {result.returncode})")
    return text


def prepare() -> None:
    subprocess.run([sys.executable, str(ROOT / "tools/assets.py")], check=True, cwd=ROOT)
    run_engine(["--headless", "--editor", "--import", "--quit"], "import.log", timeout=120)


def network_test() -> None:
    ARTIFACTS.mkdir(exist_ok=True)
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    command = [engine(), "--headless", "--path", str(ROOT), "res://tests/network_probe.tscn", "--"]
    host_log = ARTIFACTS / "network-host.log"
    process = None
    try:
        with host_log.open("w") as output:
            process = subprocess.Popen([*command, "--role=server", f"--port={port}"], stdout=output, stderr=subprocess.STDOUT, cwd=ROOT)
            deadline = time.monotonic() + 8
            while "GUESTS_NET_READY" not in host_log.read_text():
                if process.poll() is not None or time.monotonic() > deadline:
                    raise RuntimeError(f"Network host did not become ready: {host_log.read_text()}")
                time.sleep(0.05)
            client = subprocess.run([*command, "--role=client", f"--port={port}"], capture_output=True, text=True, cwd=ROOT, timeout=15)
            client_text = client.stdout + client.stderr
            (ARTIFACTS / "network-client.log").write_text(client_text)
            host_code = process.wait(timeout=15)
        host_text = host_log.read_text()
        print(host_text + client_text)
        if host_code or client.returncode or "GUESTS_NET_HOST_OK" not in host_text or "GUESTS_NET_CLIENT_OK" not in client_text or any(token in host_text + client_text for token in ERROR_TOKENS):
            raise RuntimeError("ENet two-process contract failed; see artifacts/network-*.log")
    finally:
        if process is not None and process.poll() is None:
            process.kill()
            process.wait()


def test() -> None:
    subprocess.run([sys.executable, str(ROOT / "tools/check_repo.py")], check=True, cwd=ROOT)
    run_engine(["--headless", "--script", "res://tests/run.gd"], "rules.log", "GUESTS_RULES_OK")
    network_test()
    run_engine(["--headless", "--quit-after", "45"], "scene-smoke.log")


def install_templates() -> None:
    if platform.system() == "Darwin":
        base = Path.home() / "Library/Application Support/Godot/export_templates"
    elif platform.system() == "Windows":
        base = Path(os.environ["APPDATA"]) / "Godot/export_templates"
    else:
        base = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "godot/export_templates"
    destination = base / f"{VERSION}.stable"
    needed = ("linux_debug.x86_64", "linux_release.x86_64", "version.txt")
    if all((destination / name).exists() for name in needed):
        return
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive_file(f"{PREFIX}_export_templates.tpz")) as archive:
        for name in needed:
            (destination / name).write_bytes(archive.read(f"templates/{name}"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["setup", "prepare", "test", "check", "run", "capture", "export"])
    parser.add_argument("--release", action="store_true", help="Export an optimized release instead of the debug prototype")
    arguments = parser.parse_args()
    if arguments.command == "setup":
        install_engine()
    elif arguments.command == "prepare":
        prepare()
    elif arguments.command == "test":
        test()
    elif arguments.command == "check":
        prepare()
        test()
    elif arguments.command == "run":
        subprocess.run([engine(), "--path", str(ROOT)], cwd=ROOT, check=True)
    elif arguments.command == "capture":
        run_engine(["--audio-driver", "Dummy", "--", "--capture-dir=res://artifacts/render"], "render.log", "GUESTS_CAPTURE_OK")
    elif arguments.command == "export":
        install_templates()
        (ROOT / "build").mkdir(exist_ok=True)
        mode = "--export-release" if arguments.release else "--export-debug"
        run_engine(["--headless", mode, "Linux", str(ROOT / "build/guests.x86_64")], "export.log", timeout=180)
        if platform.system() == "Linux":
            executable = ROOT / "build/guests.x86_64"
            executable.chmod(executable.stat().st_mode | 0o111)
            result = subprocess.run([str(executable), "--headless", "--quit-after", "45"], capture_output=True, text=True, timeout=45)
            text = result.stdout + result.stderr
            (ARTIFACTS / "export-smoke.log").write_text(text)
            if result.returncode or any(token in text for token in ERROR_TOKENS):
                raise RuntimeError(f"Exported client smoke failed: {text}")
            print("GUESTS_EXPORT_OK")


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, subprocess.SubprocessError, zipfile.BadZipFile) as error:
        print(f"FAILED: {error}", file=sys.stderr)
        sys.exit(1)
