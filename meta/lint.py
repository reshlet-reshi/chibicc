#!/usr/bin/env python3
import re
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


META = Path(__file__).resolve().parent
ROOT = META.parent
MYPY_CACHE = Path("/tmp/chibicc-mypy-cache")
EXTRA_LINTS = META / "lint.md"


def run(command: Sequence[str]) -> None:
    proc = subprocess.run(command, cwd=ROOT, check=False)
    if proc.returncode:
        raise SystemExit(proc.returncode)


def git_visible_paths(patterns: Sequence[str]) -> list[str]:
    proc = subprocess.run(
        [
            "git",
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "-X",
            str(ROOT / ".gitignore"),
            *patterns,
        ],
        cwd=ROOT,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if proc.returncode:
        sys.stderr.write(proc.stderr.decode())
        raise SystemExit(proc.returncode)
    if not proc.stdout:
        return []
    return [path.decode() for path in proc.stdout.rstrip(b"\0").split(b"\0")]


def extra_lints(path: Path) -> list[Path]:
    scripts: list[str] = []
    item_re = re.compile(r"^- `([^`]+)`$")

    for line in path.read_text().splitlines():
        match = item_re.match(line)
        if match:
            scripts.append(match.group(1))

    duplicates = sorted(
        {script for script in scripts if scripts.count(script) > 1},
    )
    if duplicates:
        print("duplicate extra lint entries:", file=sys.stderr)
        for script in duplicates:
            print(f"  {script}", file=sys.stderr)
        raise SystemExit(1)

    absolute = sorted(
        [script for script in scripts if Path(script).is_absolute()],
    )
    if absolute:
        print("absolute extra lint entries:", file=sys.stderr)
        for script in absolute:
            print(f"  {script}", file=sys.stderr)
        raise SystemExit(1)

    return [ROOT / script for script in scripts]


def main() -> None:
    shell_files = git_visible_paths(["*.sh", "*.sh.inc"])
    if shell_files:
        run(["shellcheck", "-x", "-s", "bash", *shell_files])

    py_files = git_visible_paths(["*.py"])
    if py_files:
        run(
            [
                sys.executable,
                "-m",
                "mypy",
                "--config-file",
                str(ROOT / "mypy.ini"),
                "--cache-dir",
                str(MYPY_CACHE),
                *py_files,
            ],
        )

    for script in extra_lints(EXTRA_LINTS):
        run([str(script)])


if __name__ == "__main__":
    main()
