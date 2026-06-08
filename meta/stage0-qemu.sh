#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)

stage0_expected_head=45d90f5955b6907dc6cdea9ebafce558359edcd3
stage0_src=$repo_root/meta/stage0-posix
stage0_init=$repo_root/meta/stage0-init.sh
stage0_seed=$stage0_src/bootstrap-seeds/POSIX/AMD64/kaem-optional-seed

kernel_url_default=https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/x86_64/netboot-3.21.7/vmlinuz-lts
kernel_sha_default=9c9ed3510f61b630725c37692944b800f18553ece787f5dd5faf2f23a7a9827b
busybox_url_default=https://busybox.net/downloads/binaries/1.35.0-x86_64-linux-musl/busybox
busybox_sha_default=6e123e7f3202a8c1e9b1f94d8941580a25135382b99e8d3e34fb858bba311348

cache=${STAGE0_CACHE:-$repo_root/.make/stage0}
qemu=${STAGE0_QEMU:-qemu-system-x86_64}
timeout_seconds=${STAGE0_QEMU_TIMEOUT:-300}
qemu_memory=${STAGE0_QEMU_MEMORY:-512M}

kernel_url=${STAGE0_KERNEL_URL:-$kernel_url_default}
kernel_sha=${STAGE0_KERNEL_SHA256:-$kernel_sha_default}
busybox_url=${STAGE0_BUSYBOX_URL:-$busybox_url_default}
busybox_sha=${STAGE0_BUSYBOX_SHA256:-$busybox_sha_default}

kernel=$cache/vmlinuz-lts
busybox=$cache/busybox
rootfs=$cache/rootfs
initramfs=$cache/initramfs.cpio.gz
qemu_log=$cache/qemu.log
success_marker=STAGE0_QEMU_SANITY_OK
repl=0

usage() {
  cat <<EOF
usage: meta/stage0-qemu.sh [--repl]

Boot stage0-posix in QEMU TCG with a pinned Linux kernel and BusyBox initramfs.
By default the guest runs the AMD64 sanity seed and powers off. With --repl,
the guest drops into BusyBox ash after setup.
EOF
}

while (($#)); do
  case $1 in
    --repl)
      repl=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "missing required command: $1" >&2
    exit 1
  fi
}

require_commands() {
  require_command cpio
  require_command curl
  require_command find
  require_command git
  require_command gzip
  require_command sha256sum
  require_command sort
  require_command tar
  require_command "$qemu"
}

sha256_matches() {
  local path=$1
  local expected=$2

  printf '%s  %s\n' "$expected" "$path" | sha256sum -c - >/dev/null 2>&1
}

fetch_artifact() {
  local destination=$1
  local url=$2
  local expected_sha=$3
  local temporary

  if [[ -f $destination ]] && sha256_matches "$destination" "$expected_sha";
  then
    return
  fi

  mkdir -p "$(dirname "$destination")"
  temporary=$destination.tmp
  rm -f "$temporary"

  curl -fsSL -o "$temporary" "$url"
  if ! sha256_matches "$temporary" "$expected_sha"; then
    echo "sha256 mismatch for $url" >&2
    rm -f "$temporary"
    exit 1
  fi

  chmod 0755 "$temporary"
  mv "$temporary" "$destination"
}

prepare_stage0_submodules() {
  local actual_head
  if [[ -x $stage0_seed ]]; then
    actual_head=$(git -C "$stage0_src" rev-parse HEAD)
    if [[ $actual_head == "$stage0_expected_head" ]]; then
      return
    fi
  fi

  git -C "$repo_root" submodule update --init --recursive meta/stage0-posix

  actual_head=$(git -C "$stage0_src" rev-parse HEAD)
  if [[ $actual_head != "$stage0_expected_head" ]]; then
    echo "meta/stage0-posix is at $actual_head" >&2
    echo "expected $stage0_expected_head" >&2
    exit 1
  fi
}

install_busybox_applets() {
  local applet
  local target

  while IFS= read -r applet; do
    target=$rootfs/$applet
    mkdir -p "$(dirname "$target")"
    ln -sf /bin/busybox "$target"
  done < <("$busybox" --list-full)
}

copy_stage0_tree() {
  mkdir -p "$rootfs/stage0-posix"
  (
    cd "$stage0_src"
    tar --exclude=.git --exclude='*/.git' -cf - .
  ) | tar -xf - -C "$rootfs/stage0-posix"
}

write_guest_config() {
  mkdir -p "$rootfs/etc"
  {
    printf 'STAGE0_REPL=%s\n' "$repl"
    printf 'STAGE0_SUCCESS_MARKER=%s\n' "$success_marker"
  } > "$rootfs/etc/stage0-qemu.conf"
}

build_initramfs() {
  rm -rf "$rootfs" "$initramfs"
  mkdir -p "$rootfs/bin" "$rootfs/dev" "$rootfs/proc" "$rootfs/sys"
  mkdir -p "$rootfs/tmp"

  install -m 0755 "$busybox" "$rootfs/bin/busybox"
  install_busybox_applets
  install -m 0755 "$stage0_init" "$rootfs/init"
  write_guest_config
  copy_stage0_tree

  mkdir -p "$(dirname "$initramfs")"
  (
    cd "$rootfs"
    find . -print0 \
      | sort -z \
      | cpio --null -o -H newc 2>/dev/null \
      | gzip -n
  ) > "$initramfs"
}

run_qemu() {
  local qemu_status
  local -a qemu_argv=(
    "$qemu"
    -accel tcg
    -m "$qemu_memory"
    -nographic
    -no-reboot
    -kernel "$kernel"
    -initrd "$initramfs"
    -append "console=ttyS0 rdinit=/init panic=-1"
  )

  if ((repl)); then
    "${qemu_argv[@]}"
    return
  fi

  : > "$qemu_log"
  set +e
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_seconds" "${qemu_argv[@]}" 2>&1 | tee "$qemu_log"
    qemu_status=${PIPESTATUS[0]}
  else
    "${qemu_argv[@]}" 2>&1 | tee "$qemu_log"
    qemu_status=${PIPESTATUS[0]}
  fi
  set -e

  if ((qemu_status != 0)); then
    echo "stage0-qemu: qemu exited with status $qemu_status" >&2
    exit "$qemu_status"
  fi

  if ! grep -F "$success_marker" "$qemu_log" >/dev/null; then
    echo "stage0-qemu: missing success marker in $qemu_log" >&2
    exit 1
  fi
}

require_commands
prepare_stage0_submodules
fetch_artifact "$kernel" "$kernel_url" "$kernel_sha"
fetch_artifact "$busybox" "$busybox_url" "$busybox_sha"
build_initramfs
run_qemu
