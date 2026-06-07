#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
pdpmake=$script_dir/pdpmake.sh

cleanup() {
  local status=$?
  "$pdpmake" clean || status=$?
  exit "$status"
}

trap cleanup EXIT

"$pdpmake" clean
"$pdpmake" test
"$pdpmake" test-stage2
