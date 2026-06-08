#!/usr/bin/env python3
import re
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


META = Path(__file__).resolve().parent
ROOT = META.parent
CHECKS = META / "check.md"


def run(command: Sequence[str]) -> None:
    proc = subprocess.run(command, cwd=ROOT, check=False)
    if proc.returncode:
        raise SystemExit(proc.returncode)


def configured_checks(path: Path) -> list[Path]:
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
        print("duplicate check entries:", file=sys.stderr)
        for script in duplicates:
            print(f"  {script}", file=sys.stderr)
        raise SystemExit(1)

    absolute = sorted(
        [script for script in scripts if Path(script).is_absolute()],
    )
    if absolute:
        print("absolute check entries:", file=sys.stderr)
        for script in absolute:
            print(f"  {script}", file=sys.stderr)
        raise SystemExit(1)

    return [ROOT / script for script in scripts]


def main() -> None:
    run([str(META / "lint.sh")])

    for script in configured_checks(CHECKS):
        run([str(script)])


if __name__ == "__main__":
    main()
