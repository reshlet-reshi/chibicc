# shellcheck disable=SC2034  # Used by scripts after sourcing this fragment.
make="make -j$(nproc)"

if [ -z "${CHIBICC:-}" ]; then
    printf '%s\n' \
        "third-party scripts must set CHIBICC before sourcing common.sh.inc" >&2
    exit 1
fi

# shellcheck disable=SC2034  # Used by scripts after sourcing this fragment.
case $CHIBICC in
/*)
    chibicc=$CHIBICC
    ;;
*)
    chibicc=$(pwd)/$CHIBICC
    ;;
esac

repo=${repo:?third-party scripts must set repo before sourcing common.sh.inc}
dir=$(basename -s .git "$repo")

set -e -x

mkdir -p thirdparty
cd thirdparty
[ -d "$dir" ] || git clone "$repo"
cd "$dir"
