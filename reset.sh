#!/bin/bash
set -e

cd "$(dirname "$0")"

read -r -p "Discard all local changes, untracked files, and ignored files? [y/N] " answer
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
