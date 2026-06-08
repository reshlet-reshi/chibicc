#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)

python3 -m mypy \
  --config-file "$repo_root/meta/mypy.ini" \
  --cache-dir /tmp/chibicc-mypy-cache \
  "$script_dir/check.py"

exec "$script_dir/check.py"
