#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)

jobs=${JOBS:-}
if [[ -z $jobs ]]; then
  if command -v nproc >/dev/null 2>&1; then
    jobs=$(nproc)
  else
    jobs=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')
  fi
fi

case $jobs in
  '' | *[!0-9]* | 0)
    echo "JOBS must be a positive integer" >&2
    exit 1
    ;;
esac

cleanup() {
  local status=$?
  env -u MAKE make -C "$repo_root" clean || status=$?
  exit "$status"
}

trap cleanup EXIT

env -u MAKE make -C "$repo_root" clean
env -u MAKE make -C "$repo_root" -j "$jobs" test-all
