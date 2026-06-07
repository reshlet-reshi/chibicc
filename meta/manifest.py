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
REPLICA = "meta/replica"
MANIFEST_ITEM = re.compile(r"^- `([^`]+)`$")


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
    lines = path.read_text().splitlines()
    paths: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        match = MANIFEST_ITEM.match(line)
        if match is None:
            i += 1
            continue

        source = match.group(1)
        line_number = i + 1
        replica_bullet = f"  - [{replica_doc_path(source)}](replica/{source}.md)"
        replica_line_number = i + 2
        if replica_line_number > len(lines) or lines[i + 1] != replica_bullet:
            raise SystemExit(
                f"{path}:{line_number}: expected replica bullet on next line: "
                f"{replica_bullet}",
            )

        after_item = i + 2
        if after_item < len(lines) and lines[after_item].startswith("  - "):
            raise SystemExit(
                f"{path}:{after_item + 1}: expected one replica bullet per path",
            )

        paths.append(source)
        i = after_item

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


def replica_doc_path(path: str) -> str:
    return f"{REPLICA}/{path}.md"


def replica_docs() -> set[str]:
    root = ROOT / REPLICA
    if not root.exists():
        return set()

    return {
        path.relative_to(ROOT).as_posix()
        for path in root.rglob("*")
        if path.is_file()
    }


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
    expected_replica_docs = {replica_doc_path(path) for path in listed}
    actual_replica_docs = replica_docs()
    missing_replica_docs = sorted(expected_replica_docs - actual_replica_docs)
    unknown_replica_docs = sorted(actual_replica_docs - expected_replica_docs)

    if (
        missing
        or unknown
        or ignored_but_listed
        or missing_replica_docs
        or unknown_replica_docs
    ):
        report("missing from manifest", missing)
        report("listed but not tracked", unknown)
        report("listed but ignored by manifest rules", ignored_but_listed)
        report("missing replica docs", missing_replica_docs)
        report("unknown replica docs", unknown_replica_docs)
        raise SystemExit(1)

    print(
        f"manifest ok: {len(listed)} listed, {len(allowed_omissions)} omitted",
    )


if __name__ == "__main__":
    main()
