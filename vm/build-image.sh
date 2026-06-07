#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
vm_dir=${CHIBICC_VM_DIR:-"$root/.vm"}
cache_dir=$vm_dir/cache
seed_dir=$vm_dir/build-seed

alpine_base_url=${ALPINE_BASE_URL:-https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/cloud}
alpine_image=${ALPINE_IMAGE:-nocloud_alpine-3.23.4-x86_64-bios-cloudinit-r0.qcow2}
toolchain_base_url=${MUSL_TOOLCHAIN_BASE_URL:-https://more.musl.cc/x86_64-linux-musl}
toolchain=${MUSL_TOOLCHAIN:-i686-linux-musl-cross.tgz}
image=${CHIBICC_VM_IMAGE:-"$vm_dir/alpine-chibicc.qcow2"}
image_dir=$(dirname "$image")
image_base=$(basename "$image")
image_tmp=$image_dir/.$image_base.tmp.$$
seed_iso=$vm_dir/build-seed.iso
log=$vm_dir/build-image.log
qemu_tmp=$vm_dir/tmp
timeout_duration=${CHIBICC_VM_BUILD_TIMEOUT:-30m}

cleanup() {
  if [ -n "${image_tmp:-}" ] && [ -e "$image_tmp" ]; then
    rm -f "$image_tmp"
  fi
}
trap cleanup EXIT HUP INT TERM

download() {
  local url=$1
  local output=$2

  if [ -s "$output" ]; then
    return
  fi

  curl -fL --retry 3 --retry-delay 2 -o "$output" "$url"
}

verify_alpine_image() {
  local expected actual

  download "$alpine_base_url/$alpine_image" "$cache_dir/$alpine_image"
  download "$alpine_base_url/$alpine_image.sha512" "$cache_dir/$alpine_image.sha512"

  expected=$(tr -d '[:space:]' < "$cache_dir/$alpine_image.sha512")
  actual=$(sha512sum "$cache_dir/$alpine_image" | awk '{print $1}')

  if [ "$expected" != "$actual" ]; then
    echo "error: checksum mismatch for $alpine_image" >&2
    echo "expected: $expected" >&2
    echo "actual:   $actual" >&2
    exit 1
  fi
}

verify_toolchain() {
  local sum_file=$cache_dir/SHA512SUMS
  local check_file=$cache_dir/$toolchain.sha512

  download "$toolchain_base_url/$toolchain" "$cache_dir/$toolchain"
  download "$toolchain_base_url/SHA512SUMS" "$sum_file"

  awk -v file="$toolchain" '$2 == file { print }' "$sum_file" > "$check_file"
  if [ ! -s "$check_file" ]; then
    echo "error: $toolchain not found in $toolchain_base_url/SHA512SUMS" >&2
    exit 1
  fi

  (
    cd "$cache_dir"
    sha512sum -c "$toolchain.sha512"
  )
}

if [ -e "$image" ] && [ "${FORCE:-0}" != 1 ]; then
  echo "$image already exists; set FORCE=1 to rebuild it"
  exit 0
fi

mkdir -p "$cache_dir" "$vm_dir" "$qemu_tmp" "$image_dir"

verify_alpine_image
verify_toolchain

rm -rf "$seed_dir"
mkdir -p "$seed_dir"
cp "$cache_dir/$toolchain" "$seed_dir/$toolchain"

cat > "$seed_dir/meta-data" <<'EOF'
instance-id: chibicc-vm-build
local-hostname: chibicc-vm
EOF

cat > "$seed_dir/user-data" <<'EOF'
#cloud-config
write_files:
  - path: /root/chibicc-vm-build.sh
    permissions: '0755'
    content: |
      #!/bin/sh
      set -eu
      log=/root/chibicc-vm-build.log
      exec > "$log" 2>&1

      retry() {
        n=0
        until "$@"; do
          n=$((n + 1))
          if [ "$n" -ge 5 ]; then
            echo "error: command failed after $n attempts: $*"
            return 1
          fi
          sleep $((n * 2))
        done
      }

      echo '=== CHIBICC_VM_BUILD_BEGIN ==='
      date -u
      cat /etc/alpine-release || true
      uname -a || true
      printf 'nameserver 10.0.2.3\n' > /etc/resolv.conf
      cat /etc/resolv.conf

      retry apk update
      retry apk add --no-cache \
        build-base bash git make perl rsync file binutils tcl-dev zlib-dev \
        readline-dev ncurses-dev linux-headers ca-certificates coreutils \
        findutils grep sed gawk diffutils patch
      update-ca-certificates
      for tool in bash git make cc file readelf rsync; do
        command -v "$tool"
      done

      mkdir -p /mnt/cidata
      toolchain=i686-linux-musl-cross.tgz
      found=
      for dev in /dev/sr0 /dev/sr1 /dev/cdrom; do
        [ -e "$dev" ] || continue
        umount /mnt/cidata >/dev/null 2>&1 || true
        if mount -o ro "$dev" /mnt/cidata >/dev/null 2>&1; then
          if [ -f "/mnt/cidata/$toolchain" ]; then
            found="/mnt/cidata/$toolchain"
            echo "TOOLCHAIN_MEDIA=$dev"
            break
          fi
        fi
      done

      if [ -z "$found" ]; then
        echo 'error: toolchain tarball not found on cidata media'
        exit 1
      fi

      rm -rf /opt/i686-linux-musl-cross
      tar -xzf "$found" -C /opt
      for tool in /opt/i686-linux-musl-cross/bin/*; do
        ln -sf "$tool" "/usr/local/bin/${tool##*/}"
      done

      i686-linux-musl-gcc -dumpmachine
      i686-linux-musl-gcc -v || true

      cat > /root/hello.c <<'HELLO_EOF'
      #include <stdio.h>
      int main(void) {
        unsigned long n = (unsigned long)sizeof(void *);
        printf("sizeof(void*)=%lu\n", n);
        return n == 4 ? 0 : 1;
      }
      HELLO_EOF

      i686-linux-musl-gcc -static -Wall -Wextra -O2 -o /root/hello32 /root/hello.c
      file /root/hello32
      readelf -h /root/hello32 | grep -E 'Class|Machine'
      /root/hello32

      {
        echo 'export PATH=/usr/local/bin:$PATH'
        echo 'export CHIBICC_VM=1'
      } > /etc/profile.d/chibicc-vm.sh

      touch /etc/chibicc-vm-ready
      echo 'CHIBICC_VM_BUILD_OK=1'
      echo '=== CHIBICC_VM_BUILD_END ==='
runcmd:
  - [ sh, -c, '/root/chibicc-vm-build.sh; rc=$?; cat /root/chibicc-vm-build.log >/dev/ttyS0; echo CHIBICC_VM_BUILD_RC=$rc >/dev/ttyS0; poweroff -f' ]
EOF

genisoimage -quiet -output "$seed_iso" -volid cidata -joliet -rock \
  "$seed_dir/user-data" "$seed_dir/meta-data" "$seed_dir/$toolchain"

rm -f "$image_tmp"
cp "$cache_dir/$alpine_image" "$image_tmp"
qemu-img resize "$image_tmp" 16G

set +e
TMPDIR="$qemu_tmp" timeout "$timeout_duration" qemu-system-x86_64 \
  -machine pc \
  -accel tcg \
  -m "${CHIBICC_VM_MEMORY:-2048}" \
  -smp "${CHIBICC_VM_CPUS:-2}" \
  -nographic \
  -no-reboot \
  -nic user,model=virtio-net-pci \
  -drive if=virtio,file="$image_tmp",format=qcow2 \
  -drive file="$seed_iso",media=cdrom,readonly=on \
  2>&1 | tee "$log"
qemu_rc=${PIPESTATUS[0]}
set -e

if [ "$qemu_rc" -ne 0 ]; then
  echo "error: QEMU build boot failed with status $qemu_rc" >&2
  exit "$qemu_rc"
fi

if ! grep -q '^CHIBICC_VM_BUILD_OK=1' "$log"; then
  echo "error: VM image build did not report success; see $log" >&2
  exit 1
fi

mv -f "$image_tmp" "$image"
image_tmp=
echo "Built $image"
