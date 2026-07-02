#!/usr/bin/env python3
"""
IPA Integrity Validator.

Checks:
  1. File exists with reasonable size (>1MB)
  2. ZIP structure integrity (BadZipFile, CRC, EOCD)
  3. Payload/ directory present
  4. .app bundle structure (Info.plist, executable)
  5. No __MACOSX / .DS_Store / AppleDouble contamination

Usage:
  python3 scripts/verify-ipa.py <path-to.ipa>
  python3 scripts/verify-ipa.py --ci <path-to.ipa>   # CI mode: exit 1 on failure
"""

import os
import sys
import zipfile
import plistlib
import hashlib
from pathlib import Path


class IPAError(Exception):
    pass


def check_file(ipa_path: Path) -> int:
    if not ipa_path.exists():
        raise IPAError(f"File not found: {ipa_path}")
    if not ipa_path.is_file():
        raise IPAError(f"Not a file: {ipa_path}")

    size = ipa_path.stat().st_size
    if size < 1_000_000:
        raise IPAError(f"File too small ({size:,} bytes), download may be incomplete")
    if size > 500_000_000:
        raise IPAError(f"File too large ({size:,} bytes)")

    print(f"  OK file size: {size:,} bytes ({size / 1024 / 1024:.1f} MB)")
    return size


def check_zip(ipa_path: Path) -> list:
    try:
        with zipfile.ZipFile(ipa_path, "r") as zf:
            names = zf.namelist()
            if not names:
                raise IPAError("IPA is an empty ZIP file")

            bad = zf.testzip()
            if bad is not None:
                raise IPAError(f"ZIP CRC check failed on: {bad}")

            print(f"  OK ZIP structure: {len(names)} entries")
            return names

    except zipfile.BadZipFile:
        import subprocess
        result = subprocess.run(
            ['unzip', '-tq', str(ipa_path)], capture_output=True, text=True
        )
        if result.returncode != 0:
            raise IPAError(f"ZIP structure invalid: {result.stderr}")
        names_result = subprocess.run(
            ['unzip', '-l', str(ipa_path)], capture_output=True, text=True
        )
        names = []
        for line in names_result.stdout.splitlines():
            parts = line.split()
            if len(parts) >= 4 and parts[-1] != 'Name' and not line.startswith('-'):
                names.append(parts[-1])
        print(f"  OK ZIP structure (fallback unzip): {len(names)} entries")
        return names


def check_payload(names: list, ipa_path: Path):
    payload_entries = [n for n in names if n.startswith("Payload/")]
    if not payload_entries:
        raise IPAError("Missing Payload/ directory in IPA")

    app_dirs = set()
    for n in payload_entries:
        parts = n.split("/")
        if len(parts) >= 2 and parts[1].endswith(".app"):
            app_dirs.add(parts[1])

    if not app_dirs:
        raise IPAError("No .app bundle found in Payload/")
    if len(app_dirs) > 1:
        raise IPAError(f"Multiple .app bundles: {app_dirs}")

    app_name = app_dirs.pop()
    app_prefix = f"Payload/{app_name}/"
    print(f"  OK App Bundle: {app_name}")

    info_plist = f"{app_prefix}Info.plist"
    if info_plist not in names:
        raise IPAError(f"Missing Info.plist: {info_plist}")

    try:
        with zipfile.ZipFile(ipa_path, "r") as zf:
            with zf.open(info_plist) as f:
                plist = plistlib.load(f)
    except Exception as e:
        raise IPAError(f"Cannot parse Info.plist: {e}")

    bundle_id = plist.get("CFBundleIdentifier", "?")
    bundle_ver = plist.get("CFBundleShortVersionString", "?")
    bundle_name = plist.get("CFBundleDisplayName") or plist.get("CFBundleName", "?")
    executable = plist.get("CFBundleExecutable", "")

    print(f"  OK Info.plist: {bundle_name} ({bundle_id}) v{bundle_ver}")

    if executable:
        exec_path = f"{app_prefix}{executable}"
        if exec_path not in names:
            raise IPAError(f"Missing executable: {exec_path}")
        print(f"  OK Executable: {executable}")


def check_contamination(names: list):
    contaminants = []
    for n in names:
        basename = os.path.basename(n.rstrip("/"))
        if basename == ".DS_Store":
            contaminants.append(f".DS_Store: {n}")
        if n.startswith("__MACOSX/"):
            contaminants.append(f"__MACOSX: {n}")
        if basename.startswith("._"):
            contaminants.append(f"AppleDouble: {n}")

    if contaminants:
        raise IPAError(
            f"ZIP contains non-standard artifacts ({len(contaminants)}):\n"
            f"  {contaminants[:5]}\n"
            f"  Fix: repack with ditto -c -k or zip -r output.ipa Payload -x '__MACOSX/*' '*.DS_Store' '._*'"
        )

    print("  OK No contamination (__MACOSX / .DS_Store / AppleDouble)")


def compute_sha256(ipa_path: Path) -> str:
    h = hashlib.sha256()
    with open(ipa_path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def verify_ipa(ipa_path: str) -> tuple[bool, str]:
    path = Path(ipa_path)
    print(f"\n=== Verifying: {path.name} ===")

    try:
        check_file(path)
        names = check_zip(path)
        check_payload(names, path)
        check_contamination(names)

        sha = compute_sha256(path)
        print(f"  OK SHA256: {sha}")
        print("=== PASS ===")
        return True, sha

    except IPAError as e:
        print(f"  FAIL: {e}")
        print("=== FAIL ===")
        return False, ""


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    ci_mode = "--ci" in sys.argv
    args = [a for a in sys.argv[1:] if a != "--ci"]

    if not args:
        print("Error: specify IPA file path")
        sys.exit(1)

    ok, sha = verify_ipa(args[0])

    if ci_mode:
        if ok:
            print(f"::notice::IPA verified | SHA256: {sha}")
        else:
            print("::error::IPA verification failed")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
