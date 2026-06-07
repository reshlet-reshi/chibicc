#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
META = ROOT / "meta"
README = META / "README.md"
REPLICA = "replica/"


def git(args: Sequence[str]) -> bytes:
    proc = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode:
        sys.stderr.write(proc.stderr.decode())
        raise SystemExit(proc.returncode)
    return proc.stdout


def git_paths(args: Sequence[str]) -> set[str]:
    out = git([*args, "-z"])
    if not out:
        return set()
    return {p.decode() for p in out.rstrip(b"\0").split(b"\0")}


def readme_paths(path: Path) -> set[str]:
    paths: list[str] = []
    item_re = re.compile(r"^- `([^`]+)`$")

    for line in path.read_text().splitlines():
        match = item_re.match(line)
        if match:
            paths.append(match.group(1))

    duplicates = sorted({p for p in paths if paths.count(p) > 1})
    if duplicates:
        report("duplicate README entries", duplicates)
        raise SystemExit(1)

    return set(paths)


def tracked_meta_paths() -> set[str]:
    paths = git_paths(["ls-files", "meta"])
    tracked: set[str] = set()
    has_replica = False

    for path in paths:
        if not path.startswith("meta/"):
            continue

        rel = path.removeprefix("meta/")
        if rel.startswith(REPLICA):
            has_replica = True
            continue

        tracked.add(rel)

    if has_replica:
        tracked.add(REPLICA)

    return tracked


def report(title: str, paths: Sequence[str]) -> None:
    if not paths:
        return
    print(f"{title}:", file=sys.stderr)
    for path in paths:
        print(f"  {path}", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate meta/README.md against tracked meta/ files",
    )
    parser.parse_args()

    tracked = tracked_meta_paths()
    listed = readme_paths(README)

    missing = sorted(tracked - listed)
    unknown = sorted(listed - tracked)

    if missing or unknown:
        report("missing from meta README", missing)
        report("listed but not tracked in meta", unknown)
        raise SystemExit(1)

    print(f"meta README ok: {len(listed)} listed")


if __name__ == "__main__":
    main()
