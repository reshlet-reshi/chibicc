# shellcheck disable=SC2034  # Used by scripts after sourcing this fragment.
make="make -j$(nproc)"
# shellcheck disable=SC2034  # Used by scripts after sourcing this fragment.
chibicc=$(pwd)/chibicc

repo=${repo:?third-party scripts must set repo before sourcing common.sh.inc}
dir=$(basename -s .git "$repo")

set -e -x

mkdir -p thirdparty
cd thirdparty
[ -d "$dir" ] || git clone "$repo"
cd "$dir"
