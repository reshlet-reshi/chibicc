#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)

cd "$repo_root"

mapfile -d '' -t py_files < <(
  git ls-files -z --cached --others -X "$repo_root/.gitignore" -- '*.py'
)

if ((${#py_files[@]})); then
  python3 -m mypy \
    --config-file "$repo_root/mypy.ini" \
    --cache-dir /tmp/chibicc-mypy-cache \
    "${py_files[@]}"
fi

"$script_dir/manifest.py"
