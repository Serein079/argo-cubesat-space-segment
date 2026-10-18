#!/usr/bin/env python3
"""Read-only verification of preserved originals and extracted report figures."""
import argparse
import hashlib
import json
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, help="Optional original The Space Segment directory")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    errors = []
    entries = json.loads((root / "provenance/original-files.json").read_text())["entries"]
    for item in entries:
        p = root / item["repository_path"]
        if not p.is_file() or p.stat().st_size != item["bytes"] or digest(p) != item["sha256"]:
            errors.append("Original copy mismatch: " + item["repository_path"])
        if args.source_root:
            source = args.source_root / item["source_relative_path"]
            if not source.is_file() or digest(source) != item["sha256"]:
                errors.append("Source mismatch: " + item["source_relative_path"])
    figures = json.loads((root / "provenance/report-figures.json").read_text())["entries"]
    for item in figures:
        p = root / item["repository_path"]
        if not p.is_file() or digest(p) != item["sha256"]:
            errors.append("Figure mismatch: " + item["repository_path"])
    if errors:
        print("FAIL\n" + "\n".join(errors))
        return 1
    print(f"PASS: {len(entries)} original code/data files and {len(figures)} report figures match SHA-256 records.")
    if args.source_root:
        print("PASS: published original files also match the supplied source directory.")
    print("This check does not run or validate MATLAB simulations.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
