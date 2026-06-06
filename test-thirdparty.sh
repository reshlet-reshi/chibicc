#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
thirdparty_dir=$root/thirdparty

if [ -n "${JOBS:-}" ]; then
  jobs=$JOBS
elif command -v nproc >/dev/null 2>&1; then
  jobs=$(nproc)
else
  jobs=1
fi

tinycc_test_jobs=${TINYCC_TEST_JOBS:-1}
libpng_test_jobs=${LIBPNG_TEST_JOBS:-$jobs}
sqlite_test_jobs=${SQLITE_TEST_JOBS:-$jobs}

usage() {
  cat <<EOF
Usage: $0 [all|tinycc|libpng|sqlite]

Supported third-party tests:
  tinycc   Build TinyCC with ./chibicc and run TinyCC's test suite
  libpng   Build libpng with ./chibicc and run libpng's test suite
  sqlite   Build SQLite with ./chibicc and run SQLite's test suite
  all      Run every supported third-party test

Environment:
  JOBS=N             Parallel make jobs (default: nproc, or 1)
  TINYCC_REPO=URL    TinyCC repository to clone
  TINYCC_COMMIT=SHA  TinyCC commit to test
  TINYCC_TEST_CC=CC  Host compiler command used by TinyCC's test harness
  TINYCC_TEST_JOBS=N Parallel jobs for TinyCC's test phase (default: 1)
  LIBPNG_REPO=URL    libpng repository to clone
  LIBPNG_COMMIT=SHA  libpng commit to test
  LIBPNG_TEST_JOBS=N Parallel jobs for libpng's test phase (default: JOBS)
  SQLITE_REPO=URL    SQLite repository to clone
  SQLITE_COMMIT=SHA  SQLite commit to test
  SQLITE_TEST_JOBS=N Parallel jobs for SQLite's test phase (default: JOBS)
EOF
}

git_with_github_https_rewrite() {
  GIT_CONFIG_COUNT=1 \
    GIT_CONFIG_KEY_0='url.https://github.com/.insteadOf' \
    GIT_CONFIG_VALUE_0='git@github.com:' \
    git "$@"
}

ensure_checkout() {
  local name=$1
  local repo=$2
  local commit=$3
  local dir=$thirdparty_dir/$name

  if [ -e "$dir" ] && [ ! -d "$dir/.git" ]; then
    echo "error: $dir exists but is not a Git checkout" >&2
    exit 1
  fi

  if [ ! -d "$dir" ]; then
    mkdir -p "$thirdparty_dir"
    (
      cd "$thirdparty_dir"
      git_with_github_https_rewrite clone "$repo" "$name"
    )
  fi

  if ! git -C "$dir" cat-file -e "$commit^{commit}" 2>/dev/null; then
    git_with_github_https_rewrite -C "$dir" fetch origin "$commit"
  fi

  git -C "$dir" reset --hard "$commit"
}

run_tinycc() {
  local repo=${TINYCC_REPO:-git@github.com:TinyCC/tinycc.git}
  local commit=${TINYCC_COMMIT:-df67d8617b7d1d03a480a28f9f901848ffbfb7ec}
  local host_cc=${TINYCC_TEST_CC:-cc -Wno-error=implicit-int -Wno-error=implicit-function-declaration}
  local dir=$thirdparty_dir/tinycc

  cd "$root"
  make chibicc
  ensure_checkout tinycc "$repo" "$commit"

  (
    cd "$dir"
    ./configure --cc="$root/chibicc"
    make -j"$jobs" clean
    make -j"$jobs"
    make -j"$tinycc_test_jobs" "CC=$host_cc" test
  )
}

run_libpng() {
  local repo=${LIBPNG_REPO:-git@github.com:rui314/libpng.git}
  local commit=${LIBPNG_COMMIT:-dbe3e0c43e549a1602286144d94b0666549b18e6}
  local dir=$thirdparty_dir/libpng

  cd "$root"
  make chibicc
  ensure_checkout libpng "$repo" "$commit"

  (
    cd "$dir"
    CC="$root/chibicc" ./configure
    sed -i 's/^wl=.*/wl=-Wl,/; s/^pic_flag=.*/pic_flag=-fPIC/' libtool
    make -j"$jobs" clean
    make -j"$jobs"
    make -j"$libpng_test_jobs" test
  )
}

run_sqlite() {
  local repo=${SQLITE_REPO:-git@github.com:sqlite/sqlite.git}
  local commit=${SQLITE_COMMIT:-86f477edaa17767b39c7bae5b67cac8580f7a8c1}
  local dir=$thirdparty_dir/sqlite

  cd "$root"
  make chibicc
  ensure_checkout sqlite "$repo" "$commit"

  (
    cd "$dir"
    CC="$root/chibicc" CFLAGS=-D_GNU_SOURCE ./configure
    sed -i 's/^wl=.*/wl=-Wl,/; s/^pic_flag=.*/pic_flag=-fPIC/' libtool
    make -j"$jobs" clean
    make -j"$jobs"
    make -j"$sqlite_test_jobs" test
  )
}

run_all() {
  run_tinycc
  run_libpng
  run_sqlite
}

if [ $# -eq 0 ]; then
  usage
  exit 2
fi

case $1 in
  all)
    run_all
    ;;
  tinycc)
    run_tinycc
    ;;
  libpng)
    run_libpng
    ;;
  sqlite)
    run_sqlite
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
