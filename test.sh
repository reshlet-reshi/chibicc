#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)

cd "$root"
make test-all
./test-thirdparty.sh all
