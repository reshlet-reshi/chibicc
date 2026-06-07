#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)
cd "$repo_root"

prompt="Discard all local changes, untracked files, and ignored files? [y/N] "
read -r -p "$prompt" answer
case "$answer" in
  y|Y|yes|YES)
    git reset --hard HEAD
    git clean -fdx
    ;;
  *)
    echo "Aborted."
    exit 1
    ;;
esac
