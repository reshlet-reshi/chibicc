#!/usr/bin/env python3
import argparse
import subprocess
import sys
import tempfile
from collections.abc import Sequence
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "meta" / "manifest.md"
REPLICA = "meta/replica"
TABLE_HEADER = "| Path | Replica |"
TABLE_SEPARATOR = "| --- | --- |"


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
    headers = [i for i, line in enumerate(lines) if line == TABLE_HEADER]
    if len(headers) != 1:
        raise SystemExit(f"{path}: expected exactly one {TABLE_HEADER} table")

    header_index = headers[0]
    separator_index = header_index + 1
    if separator_index >= len(lines) or lines[separator_index] != TABLE_SEPARATOR:
        raise SystemExit(f"{path}: expected {TABLE_SEPARATOR} after table header")

    paths: list[str] = []
    for line_number, line in enumerate(
        lines[separator_index + 1 :],
        start=separator_index + 2,
    ):
        if not line.startswith("|"):
            break

        cells = table_cells(line)
        if cells is None:
            raise SystemExit(
                f"{path}:{line_number}: expected "
                "| `path` | [meta/replica/path.md](replica/path.md) |",
            )

        source_cell, replica_cell = cells
        source = backticked_value(source_cell)
        link = markdown_link(replica_cell)
        if source is None or link is None:
            raise SystemExit(
                f"{path}:{line_number}: expected "
                "| `path` | [meta/replica/path.md](replica/path.md) |",
            )

        link_text, link_target = link
        expected_link_text = replica_doc_path(source)
        expected_link_target = f"replica/{source}.md"
        if link_text != expected_link_text or link_target != expected_link_target:
            raise SystemExit(
                f"{path}:{line_number}: expected replica link "
                f"[{expected_link_text}]({expected_link_target})",
            )

        paths.append(source)

    duplicates = sorted({p for p in paths if paths.count(p) > 1})
    if duplicates:
        report("duplicate manifest entries", duplicates)
        raise SystemExit(1)

    return set(paths)


def table_cells(line: str) -> tuple[str, str] | None:
    if not line.startswith("| ") or not line.endswith(" |"):
        return None

    cells = line.removeprefix("| ").removesuffix(" |").split(" | ")
    if len(cells) != 2:
        return None

    return cells[0], cells[1]


def backticked_value(cell: str) -> str | None:
    if not cell.startswith("`") or not cell.endswith("`"):
        return None

    value = cell[1:-1]
    if not value or "`" in value:
        return None

    return value


def markdown_link(cell: str) -> tuple[str, str] | None:
    separator = "]("
    separator_index = cell.find(separator)
    if not cell.startswith("[") or not cell.endswith(")") or separator_index == -1:
        return None

    text = cell[1:separator_index]
    target = cell[separator_index + len(separator) : -1]
    if not text or not target:
        return None

    return text, target


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
