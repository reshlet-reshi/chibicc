#!/usr/bin/env python3
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


META = Path(__file__).resolve().parent
ROOT = META.parent
MYPY_CACHE = Path("/tmp/chibicc-mypy-cache")


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

    run([sys.executable, str(META / "README.py")])
    run([sys.executable, str(META / "manifest.py")])


if __name__ == "__main__":
    main()
