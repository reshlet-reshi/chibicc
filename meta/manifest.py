#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "meta" / "manifest.md"


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


def extract_gitignore_block(path: Path) -> str:
    lines = path.read_text().splitlines()
    blocks: list[list[str]] = []
    current: list[str] | None = None

    for line in lines:
        if current is None:
            if line == "```gitignore":
                current = []
            continue

        if line == "```":
            blocks.append(current)
            current = None
            continue

        current.append(line)

    if current is not None:
        raise SystemExit(f"{path}: unclosed gitignore fence")
    if len(blocks) != 1:
        raise SystemExit(f"{path}: expected exactly one gitignore fence")

    return "\n".join(blocks[0]) + "\n"


def manifest_paths(path: Path) -> set[str]:
    paths: list[str] = []
    row_re = re.compile(r"^\| `([^`]+)` \|")

    for line in path.read_text().splitlines():
        match = row_re.match(line)
        if match:
            paths.append(match.group(1))

    duplicates = sorted({p for p in paths if paths.count(p) > 1})
    if duplicates:
        report("duplicate manifest entries", duplicates)
        raise SystemExit(1)

    return set(paths)


def ignored_by_manifest(patterns: str) -> set[str]:
    with tempfile.NamedTemporaryFile("w", encoding="utf-8") as f:
        f.write(patterns)
        f.flush()
        return git_paths(["ls-files", "-ci", "-X", f.name])


def ignored_by_root_gitignore() -> set[str]:
    return git_paths(["ls-files", "-ci", "-X", str(ROOT / ".gitignore")])


def report(title: str, paths: Sequence[str]) -> None:
    if not paths:
        return
    print(f"{title}:", file=sys.stderr)
    for path in paths:
        print(f"  {path}", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate meta/manifest.md against its embedded ignore rules",
    )
    parser.parse_args()

    tracked = git_paths(["ls-files"])
    allowed_omissions = ignored_by_manifest(extract_gitignore_block(MANIFEST))
    allowed_omissions |= ignored_by_root_gitignore()
    required = tracked - allowed_omissions
    listed = manifest_paths(MANIFEST)

    missing = sorted(required - listed)
    unknown = sorted(listed - tracked)
    ignored_but_listed = sorted(listed & allowed_omissions)

    if missing or unknown or ignored_but_listed:
        report("missing from manifest", missing)
        report("listed but not tracked", unknown)
        report("listed but ignored by manifest rules", ignored_but_listed)
        raise SystemExit(1)

    print(
        f"manifest ok: {len(listed)} listed, {len(allowed_omissions)} omitted",
    )


if __name__ == "__main__":
    main()
