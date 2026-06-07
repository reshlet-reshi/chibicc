#!/usr/bin/env python3
import argparse
import re
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
META = ROOT / "meta"
BRANCHES = META / "branches.md"
LOCAL_PREFIX = "refs/heads/"
REMOTE_PREFIX = "refs/remotes/"


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


def git_lines(args: Sequence[str]) -> list[str]:
    out = git(args)
    if not out:
        return []
    return out.decode().splitlines()


def current_branches() -> set[str]:
    refs = git_lines(
        ["for-each-ref", "--format=%(refname)", "refs/heads", "refs/remotes"],
    )
    branches: set[str] = set()

    for ref in refs:
        if ref.startswith(LOCAL_PREFIX):
            branches.add(ref.removeprefix(LOCAL_PREFIX))
        elif ref.startswith(REMOTE_PREFIX):
            branches.add(ref.removeprefix(REMOTE_PREFIX))

    return branches


def listed_branches(path: Path) -> list[str]:
    branches: list[str] = []
    item_re = re.compile(r"^- `([^`]+)`$")

    for line in path.read_text().splitlines():
        match = item_re.match(line)
        if match:
            branches.append(match.group(1))

    duplicates = sorted(
        {branch for branch in branches if branches.count(branch) > 1},
    )
    if duplicates:
        report("duplicate branch manifest entries", duplicates)
        raise SystemExit(1)

    return branches


def report(title: str, branches: Sequence[str]) -> None:
    if not branches:
        return
    print(f"{title}:", file=sys.stderr)
    for branch in branches:
        print(f"  {branch}", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate meta/branches.md against current Git branches",
    )
    parser.parse_args()

    current = current_branches()
    listed = listed_branches(BRANCHES)
    listed_set = set(listed)

    missing = sorted(current - listed_set)
    unknown = sorted(listed_set - current)

    if missing or unknown:
        report("missing from branch manifest", missing)
        report("listed but not a current branch", unknown)
        raise SystemExit(1)

    print(f"branch manifest ok: {len(listed)} listed")


if __name__ == "__main__":
    main()
