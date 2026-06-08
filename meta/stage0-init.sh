#!/bin/busybox sh
# shellcheck shell=sh
set -u

PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH
BB=/bin/busybox

mount_fs() {
  type=$1
  source=$2
  target=$3

  "$BB" mkdir -p "$target"
  "$BB" mount -t "$type" "$source" "$target" >/dev/null 2>&1 || true
}

mount_fs proc proc /proc
mount_fs sysfs sysfs /sys
mount_fs devtmpfs devtmpfs /dev

if [ ! -e /dev/console ]; then
  "$BB" mknod /dev/console c 5 1 >/dev/null 2>&1 || true
fi
if [ ! -e /dev/null ]; then
  "$BB" mknod /dev/null c 1 3 >/dev/null 2>&1 || true
fi

exec </dev/console >/dev/console 2>&1 || true

STAGE0_LIVE_BOOTSTRAP=0
STAGE0_REPL=0
STAGE0_SUCCESS_MARKER=STAGE0_QEMU_SANITY_OK

if [ -r /etc/stage0-qemu.conf ]; then
  # shellcheck disable=SC1091
  . /etc/stage0-qemu.conf
fi

run_sanity() {
  sha256sum=/stage0-posix/AMD64/bin/sha256sum
  seed=/stage0-posix/bootstrap-seeds/POSIX/AMD64/kaem-optional-seed

  if [ -x "$sha256sum" ]; then
    cd /stage0-posix || return 1
    if "$sha256sum" -c amd64.answers; then
      echo "stage0-qemu: AMD64 bootstrap answers already verify"
      return 0
    fi
    echo "stage0-qemu: preseed check failed; running seed bootstrap" >&2
  fi

  if [ ! -x "$seed" ]; then
    echo "stage0-qemu: missing executable AMD64 seed: $seed" >&2
    return 1
  fi

  cd /stage0-posix || return 1
  "$seed"
}

run_live_bootstrap() {
  sha256sum=/AMD64/bin/sha256sum
  seed=/bootstrap-seeds/POSIX/AMD64/kaem-optional-seed

  if [ -x "$sha256sum" ]; then
    cd / || return 1
    if "$sha256sum" -c amd64.answers; then
      echo "stage0-qemu: AMD64 bootstrap answers already verify"
      ARCH=amd64
      ARCH_DIR=AMD64
      export ARCH ARCH_DIR
      AMD64/bin/kaem --verbose --strict --file after.kaem
      return
    fi
    echo "stage0-qemu: preseed check failed; running seed bootstrap" >&2
  fi

  if [ ! -x "$seed" ]; then
    echo "stage0-qemu: missing executable AMD64 seed: $seed" >&2
    return 1
  fi

  cd / || return 1
  "$seed"
}

status=0
if [ "$STAGE0_LIVE_BOOTSTRAP" = 1 ]; then
  run_live_bootstrap || status=$?
else
  run_sanity || status=$?
fi

if [ "$status" -eq 0 ]; then
  echo "$STAGE0_SUCCESS_MARKER"
else
  echo "stage0-qemu: sanity command failed with status $status" >&2
fi

if [ "$STAGE0_REPL" = 1 ]; then
  echo "stage0-qemu: entering BusyBox ash"
  "$BB" setsid "$BB" cttyhack "$BB" ash
fi

"$BB" poweroff -f >/dev/null 2>&1 || "$BB" poweroff >/dev/null 2>&1 || true
"$BB" halt -f >/dev/null 2>&1 || "$BB" reboot -f >/dev/null 2>&1 || true

echo "stage0-qemu: unable to power off" >&2
"$BB" sleep 5
exit "$status"
