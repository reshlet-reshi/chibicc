#!/bin/sh
set -u

PATH=/bin:/sbin:/usr/bin:/usr/sbin
export PATH

mount_fs() {
  type=$1
  source=$2
  target=$3

  mkdir -p "$target"
  mount -t "$type" "$source" "$target" >/dev/null 2>&1 || true
}

mount_fs proc proc /proc
mount_fs sysfs sysfs /sys
mount_fs devtmpfs devtmpfs /dev

if [ ! -e /dev/console ]; then
  mknod /dev/console c 5 1 >/dev/null 2>&1 || true
fi
if [ ! -e /dev/null ]; then
  mknod /dev/null c 1 3 >/dev/null 2>&1 || true
fi

exec </dev/console >/dev/console 2>&1 || true

STAGE0_REPL=0
STAGE0_SUCCESS_MARKER=STAGE0_QEMU_SANITY_OK

if [ -r /etc/stage0-qemu.conf ]; then
  # shellcheck disable=SC1091
  . /etc/stage0-qemu.conf
fi

run_sanity() {
  seed=/stage0-posix/bootstrap-seeds/POSIX/AMD64/kaem-optional-seed

  if [ ! -x "$seed" ]; then
    echo "stage0-qemu: missing executable AMD64 seed: $seed" >&2
    return 1
  fi

  cd /stage0-posix || return 1
  "$seed"
}

status=0
run_sanity || status=$?

if [ "$status" -eq 0 ]; then
  echo "$STAGE0_SUCCESS_MARKER"
else
  echo "stage0-qemu: sanity command failed with status $status" >&2
fi

if [ "$STAGE0_REPL" = 1 ]; then
  echo "stage0-qemu: entering BusyBox ash"
  exec /bin/ash
fi

poweroff -f >/dev/null 2>&1 || poweroff >/dev/null 2>&1 || true
halt -f >/dev/null 2>&1 || reboot -f >/dev/null 2>&1 || true

echo "stage0-qemu: unable to power off" >&2
sleep 5
exit "$status"
