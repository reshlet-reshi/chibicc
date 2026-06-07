#!/bin/bash
set -euo pipefail

caller_pwd=$(pwd)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)
script_path=$script_dir/pdpmake.sh

pdpmake_src=$repo_root/meta/pdpmake
pdpmake_build=$repo_root/.make/pdpmake
pdpmake=$pdpmake_build/make
stamp=$pdpmake_build/.pdpmake-head

pdpmake_head=$(git -C "$pdpmake_src" rev-parse HEAD)
needs_build=0

if [[ ! -x $pdpmake || ! -f $stamp ]]; then
  needs_build=1
elif [[ $(<"$stamp") != "$pdpmake_head" ]]; then
  needs_build=1
fi

if ((needs_build)); then
  rm -rf "$pdpmake_build"
  mkdir -p "$pdpmake_build"
  git -C "$pdpmake_src" archive HEAD | tar -x -C "$pdpmake_build"

  read -r -a cc_argv <<< "${PDPMAKE_CC:-cc}"
  sources=(
    check.c
    input.c
    macro.c
    main.c
    make.c
    modtime.c
    rules.c
    target.c
    utils.c
  )
  objects=()

  (
    cd "$pdpmake_build"
    for source in "${sources[@]}"; do
      object=${source%.c}.o
      "${cc_argv[@]}" -c -o "$object" "$source"
      objects+=("$object")
    done
    "${cc_argv[@]}" -o make "${objects[@]}"
  )

  printf '%s\n' "$pdpmake_head" > "$stamp"
fi

cd "$caller_pwd"
export MAKE=$script_path
exec "$pdpmake" "$@" "MAKE=$script_path"
