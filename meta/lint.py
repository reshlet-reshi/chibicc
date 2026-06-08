#!/usr/bin/env python3
import os
import re
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


META = Path(__file__).resolve().parent
ROOT = META.parent
MYPY_CACHE = Path("/tmp/chibicc-mypy-cache")
EXTRA_LINTS = META / "lint.md"
REPLICA = Path("meta/replica")
MAKEFILE = ROOT / "Makefile"
TEST_MAKEFILE = ROOT / "test" / "Makefile"
MYPY_CONFIG = Path("meta/mypy.ini")
ALLOWED_EXTENSIONLESS = {"LICENSE", "Makefile"}
SHELL_EXTENSIONS = {".sh", ".sh.inc"}
NOOP_EXTENSIONS = {
    ".c",
    ".gitignore",
    ".gitmodules",
    ".h",
    ".md",
}
RECOGNIZED_EXTENSIONS = NOOP_EXTENSIONS | SHELL_EXTENSIONS | {".ini", ".py"}
MAKE_VARIABLE_REF_RE = re.compile(r"^\$\(([A-Za-z0-9_]+)\)$")


def run(command: Sequence[str]) -> None:
    proc = subprocess.run(command, cwd=ROOT, check=False)
    if proc.returncode:
        raise SystemExit(proc.returncode)


def git_visible_paths() -> set[Path]:
    proc = subprocess.run(
        [
            "git",
            "ls-files",
            "-z",
            "--cached",
            "--others",
            "-X",
            str(ROOT / ".gitignore"),
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
        return set()
    return {
        Path(path.decode())
        for path in proc.stdout.rstrip(b"\0").split(b"\0")
    }


def git_source_dist_paths() -> set[Path]:
    proc = subprocess.run(
        [
            "git",
            "ls-files",
            "-z",
            "--",
            ".",
            ":!AGENTS.md",
            ":!meta",
            ":!.gitignore",
            ":!.gitmodules",
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
        return set()
    return {
        path
        for path in (
            Path(path.decode())
            for path in proc.stdout.rstrip(b"\0").split(b"\0")
        )
        if (ROOT / path).exists()
    }


def walk_visible_files() -> list[Path]:
    visible = git_visible_paths()
    walked: list[Path] = []

    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = sorted(
            dirname for dirname in dirnames if dirname != ".git"
        )

        for filename in sorted(filenames):
            path = Path(dirpath) / filename
            rel = path.relative_to(ROOT)
            if rel in visible:
                walked.append(rel)

    return sorted(walked)


def full_extension(path: Path) -> str:
    index = path.name.find(".")
    if index == -1:
        return ""
    return path.name[index:]


def is_replica_path(path: Path) -> bool:
    return path == REPLICA or REPLICA in path.parents


def make_assignment_value(line: str, variable: str) -> str | None:
    if not line.startswith(variable):
        return None

    rest = line[len(variable) :].lstrip()
    for operator in (":=", "+=", "?=", "="):
        if rest.startswith(operator):
            return rest[len(operator) :].lstrip()

    return None


def raw_make_variable_words(path: Path, variable: str) -> list[str]:
    chunks: list[str] = []
    collecting = False

    for line in path.read_text().splitlines():
        if not collecting:
            value = make_assignment_value(line, variable)
            if value is None:
                continue
            chunk = value.rstrip()
        else:
            chunk = line.rstrip()

        if chunk.endswith("\\"):
            chunks.append(chunk[:-1])
            collecting = True
            continue

        chunks.append(chunk)
        collecting = False
        break

    if not chunks:
        print(f"missing Makefile variable: {variable}", file=sys.stderr)
        raise SystemExit(1)

    return " ".join(chunks).split()


def make_variable_words(
    path: Path,
    variable: str,
    seen: set[str] | None = None,
) -> list[str]:
    if seen is None:
        seen = set()
    if variable in seen:
        print(f"recursive Makefile variable: {variable}", file=sys.stderr)
        raise SystemExit(1)

    seen.add(variable)
    expanded: list[str] = []
    for word in raw_make_variable_words(path, variable):
        match = MAKE_VARIABLE_REF_RE.match(word)
        if match is None:
            expanded.append(word)
            continue
        expanded.extend(make_variable_words(path, match.group(1), seen))
    seen.remove(variable)
    return expanded


def source_archive_files() -> list[Path]:
    root_files = [
        Path(word) for word in make_variable_words(MAKEFILE, "FILES")
    ]
    test_files = [
        Path("test") / word
        for word in make_variable_words(TEST_MAKEFILE, "FILES")
    ]
    return root_files + test_files


def check_source_archive_files() -> None:
    archive_files = source_archive_files()
    duplicates = sorted(
        {path for path in archive_files if archive_files.count(path) > 1},
    )
    if duplicates:
        print("duplicate source archive entries:", file=sys.stderr)
        for path in duplicates:
            print(f"  {path}", file=sys.stderr)
        raise SystemExit(1)

    listed = set(archive_files)
    tracked = git_source_dist_paths()
    missing = sorted(tracked - listed)
    unknown = sorted(listed - tracked)

    if not missing and not unknown:
        return

    print("source archive file list mismatch:", file=sys.stderr)
    if missing:
        print("  missing FILES entries:", file=sys.stderr)
        for path in missing:
            print(f"    {path}", file=sys.stderr)
    if unknown:
        print("  unknown FILES entries:", file=sys.stderr)
        for path in unknown:
            print(f"    {path}", file=sys.stderr)
    raise SystemExit(1)


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


def unrecognized_files(paths: Sequence[Path]) -> dict[str, list[Path]]:
    findings: dict[str, list[Path]] = {}

    for path in paths:
        extension = full_extension(path)
        if not extension:
            if path.name in ALLOWED_EXTENSIONLESS:
                continue
            findings.setdefault("<extensionless>", []).append(path)
            continue

        if extension == ".ini" and path != MYPY_CONFIG:
            findings.setdefault("unexpected .ini", []).append(path)
            continue

        if extension not in RECOGNIZED_EXTENSIONS:
            findings.setdefault(extension, []).append(path)

    return findings


def report_unrecognized_files(findings: dict[str, list[Path]]) -> None:
    if not findings:
        return

    print("unrecognized file extensions:", file=sys.stderr)
    for extension in sorted(findings):
        print(f"  {extension}:", file=sys.stderr)
        for path in findings[extension]:
            print(f"    {path}", file=sys.stderr)


def lint_ruff(paths: Sequence[Path]) -> None:
    if not paths:
        return

    run(
        [
            sys.executable,
            "-m",
            "ruff",
            "check",
            "--no-cache",
            *[str(path) for path in paths],
        ],
    )


def lint_python(paths: Sequence[Path]) -> None:
    if not paths:
        return

    run(
        [
            sys.executable,
            "-m",
            "mypy",
            "--config-file",
            str(ROOT / MYPY_CONFIG),
            "--cache-dir",
            str(MYPY_CACHE),
            *[str(path) for path in paths],
        ],
    )


def lint_mypy_config(path: Path) -> None:
    run(
        [
            sys.executable,
            "-m",
            "mypy",
            "--config-file",
            str(path),
            "--cache-dir",
            str(MYPY_CACHE),
            "--warn-unused-configs",
            "-c",
            "pass",
        ],
    )


def lint_shell(path: Path) -> None:
    run(["shellcheck", "-x", "-s", "bash", str(path)])


def lint_noop(path: Path) -> None:
    return


def lint_file(path: Path, python_paths: list[Path]) -> None:
    extension = full_extension(path)

    if extension == ".py":
        python_paths.append(path)
    elif extension == ".ini":
        lint_mypy_config(path)
    elif extension in SHELL_EXTENSIONS:
        lint_shell(path)
    else:
        lint_noop(path)


def main() -> None:
    check_source_archive_files()

    files = [
        path for path in walk_visible_files() if not is_replica_path(path)
    ]
    findings = unrecognized_files(files)
    if findings:
        report_unrecognized_files(findings)
        raise SystemExit(1)

    python_paths: list[Path] = []
    for path in files:
        lint_file(path, python_paths)
    lint_ruff(python_paths)
    lint_python(python_paths)

    for script in extra_lints(EXTRA_LINTS):
        run([str(script)])


if __name__ == "__main__":
    main()
