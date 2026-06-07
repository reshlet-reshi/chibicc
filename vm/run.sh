#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
vm_dir=${CHIBICC_VM_DIR:-"$root/.vm"}
image=${CHIBICC_VM_IMAGE:-"$vm_dir/alpine-chibicc.qcow2"}
seed_dir=$vm_dir/run-seed
seed_iso=$vm_dir/run-seed.iso
log=$vm_dir/run.log
qemu_tmp=$vm_dir/tmp
timeout_duration=${CHIBICC_VM_RUN_TIMEOUT:-6h}
default_cmd='./test.sh'

cmd=${*:-$default_cmd}

tinycc_default_commit=df67d8617b7d1d03a480a28f9f901848ffbfb7ec
libpng_default_commit=dbe3e0c43e549a1602286144d94b0666549b18e6
sqlite_default_commit=86f477edaa17767b39c7bae5b67cac8580f7a8c1

tinycc_commit=${TINYCC_COMMIT:-$tinycc_default_commit}
libpng_commit=${LIBPNG_COMMIT:-$libpng_default_commit}
sqlite_commit=${SQLITE_COMMIT:-$sqlite_default_commit}

submodule_help='run: git submodule update --init --recursive'

validate_submodule() {
  local name=$1
  local envvar=$2
  local expected=$3
  local default=$4
  local required=$5
  local dir=$root/thirdparty/$name
  local actual
  local ignored
  local untracked

  if [ ! -f "$required" ]; then
    echo "error: missing third-party submodule content: $required" >&2
    echo "$submodule_help" >&2
    exit 1
  fi

  if ! git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: thirdparty/$name is not a Git checkout" >&2
    echo "$submodule_help" >&2
    exit 1
  fi

  actual=$(git -C "$dir" rev-parse HEAD)
  if [ "$actual" != "$expected" ]; then
    echo "error: thirdparty/$name is at $actual, expected $expected" >&2
    if [ "$expected" != "$default" ]; then
      echo "checkout thirdparty/$name to $expected, or unset $envvar to use the VM default" >&2
    else
      echo "$submodule_help" >&2
    fi
    exit 1
  fi

  if ! git -C "$dir" diff --quiet || ! git -C "$dir" diff --cached --quiet; then
    echo "error: thirdparty/$name has tracked local changes" >&2
    echo "$submodule_help" >&2
    exit 1
  fi

  untracked=$(git -C "$dir" ls-files --others --exclude-standard)
  ignored=$(git -C "$dir" ls-files --others --ignored --exclude-standard)
  if [ -n "$untracked" ] || [ -n "$ignored" ]; then
    echo "error: thirdparty/$name has files outside the pinned commit" >&2
    if [ -n "$untracked" ]; then
      echo "untracked files:" >&2
      printf '%s\n' "$untracked" | sed 's/^/  /' >&2
    fi
    if [ -n "$ignored" ]; then
      echo "ignored generated files:" >&2
      printf '%s\n' "$ignored" | sed 's/^/  /' >&2
    fi
    echo "remove these files before running the VM tests" >&2
    exit 1
  fi
}

reject_inline_commit_overrides() {
  local target
  local var

  for var in TINYCC_COMMIT LIBPNG_COMMIT SQLITE_COMMIT; do
    if [[ $cmd == *"$var="* ]]; then
      case $var in
        TINYCC_COMMIT) target=tinycc ;;
        LIBPNG_COMMIT) target=libpng ;;
        SQLITE_COMMIT) target=sqlite ;;
      esac
      echo "error: VM command contains inline $var override" >&2
      echo "vm/run.sh strips third-party Git metadata before running guest commands, so inline commit overrides cannot be verified before boot." >&2
      echo "pass $var to vm/run.sh itself and checkout the matching submodule commit first, for example:" >&2
      echo "  $var=<sha> ./vm/run.sh \"./test-thirdparty.sh $target\"" >&2
      exit 1
    fi
  done
}

reject_inline_commit_overrides

if [ ! -f "$image" ]; then
  echo "error: missing VM image $image; run ./vm/build-image.sh first" >&2
  exit 1
fi

validate_submodule tinycc TINYCC_COMMIT "$tinycc_commit" "$tinycc_default_commit" "$root/thirdparty/tinycc/configure"
validate_submodule libpng LIBPNG_COMMIT "$libpng_commit" "$libpng_default_commit" "$root/thirdparty/libpng/configure"
validate_submodule sqlite SQLITE_COMMIT "$sqlite_commit" "$sqlite_default_commit" "$root/thirdparty/sqlite/configure"

mkdir -p "$vm_dir" "$qemu_tmp"
rm -rf "$seed_dir"
mkdir -p "$seed_dir"

cat > "$seed_dir/meta-data" <<EOF
instance-id: chibicc-vm-run-$(date +%s)-$$
local-hostname: chibicc-vm
EOF

printf '%s\n' "$cmd" > "$seed_dir/run-command"

cat > "$seed_dir/user-data" <<'EOF'
#cloud-config
write_files:
  - path: /root/chibicc-vm-run.sh
    permissions: '0755'
    content: |
      #!/bin/sh
      set -u
      log=/root/chibicc-vm-run.log
      exec > "$log" 2>&1

      finish() {
        rc=$1
        echo "CHIBICC_VM_RUN_RC=$rc"
        echo '=== CHIBICC_VM_RUN_END ==='
        cat "$log" >/dev/ttyS0
        echo "CHIBICC_VM_RUN_RC=$rc" >/dev/ttyS0
        poweroff -f
      }

      setup_fail() {
        echo "error: $1"
        finish 1
      }

      echo '=== CHIBICC_VM_RUN_BEGIN ==='
      date -u
      cat /etc/alpine-release || true
      uname -a || true
      i686-linux-musl-gcc -dumpmachine || true

      mkdir -p /mnt/cidata || setup_fail 'failed to create cidata mount point'
      command_file=
      for dev in /dev/sr0 /dev/sr1 /dev/cdrom; do
        [ -e "$dev" ] || continue
        umount /mnt/cidata >/dev/null 2>&1 || true
        if mount -o ro "$dev" /mnt/cidata >/dev/null 2>&1; then
          if [ -f /mnt/cidata/run-command ]; then
            command_file=/mnt/cidata/run-command
            break
          fi
        fi
      done

      if [ -z "$command_file" ]; then
        echo 'error: run-command not found on cidata media'
        finish 1
      fi

      command_text=$(cat "$command_file")
      echo '--- command ---'
      printf '%s\n' "$command_text"

      mkdir -p /mnt/chibicc-src /work || setup_fail 'failed to create work mount points'
      if ! mount -t 9p -o trans=virtio,version=9p2000.L,ro chibicc_src /mnt/chibicc-src; then
        echo 'error: failed to mount chibicc_src 9p share'
        finish 1
      fi

      rm -rf /work/chibicc || setup_fail 'failed to remove previous work tree'
      mkdir -p /work/chibicc || setup_fail 'failed to create work tree'
      rsync -a --delete \
        --exclude='.git' \
        --exclude='.vm' \
        --exclude='chibicc' \
        --exclude='*.o' \
        --exclude='test/*.exe' \
        --exclude='stage2' \
        /mnt/chibicc-src/ /work/chibicc/ || setup_fail 'failed to copy source tree'
      chmod -R u+rwX /work/chibicc || setup_fail 'failed to make work tree writable'

      cd /work/chibicc || setup_fail 'failed to enter work tree'
      export JOBS="${JOBS:-2}"
      export TINYCC_TEST_JOBS="${TINYCC_TEST_JOBS:-1}"
      export THIRDPARTY_NO_NETWORK="${THIRDPARTY_NO_NETWORK:-1}"
      export THIRDPARTY_TRUST_EXISTING="${THIRDPARTY_TRUST_EXISTING:-1}"
      /bin/bash -lc "$command_text"
      finish $?
runcmd:
  - [ sh, -c, '/root/chibicc-vm-run.sh' ]
EOF

genisoimage -quiet -output "$seed_iso" -volid cidata -joliet -rock \
  "$seed_dir/user-data" "$seed_dir/meta-data" "$seed_dir/run-command"

set +e
TMPDIR="$qemu_tmp" timeout "$timeout_duration" qemu-system-x86_64 \
  -machine pc \
  -accel tcg \
  -m "${CHIBICC_VM_MEMORY:-2048}" \
  -smp "${CHIBICC_VM_CPUS:-2}" \
  -nographic \
  -no-reboot \
  -snapshot \
  -nic user,model=virtio-net-pci \
  -drive if=virtio,file="$image",format=qcow2 \
  -drive file="$seed_iso",media=cdrom,readonly=on \
  -virtfs local,path="$root",mount_tag=chibicc_src,security_model=none,readonly=on \
  2>&1 | tee "$log"
qemu_rc=${PIPESTATUS[0]}
set -e

if [ "$qemu_rc" -ne 0 ]; then
  echo "error: QEMU run failed with status $qemu_rc" >&2
  exit "$qemu_rc"
fi

if ! grep -q '^=== CHIBICC_VM_RUN_END ===' "$log"; then
  echo "error: VM run did not finish cleanly; see $log" >&2
  exit 1
fi

run_rc=$(sed -n 's/^CHIBICC_VM_RUN_RC=//p' "$log" | tail -n 1 | tr -d '\r')
if [ -z "$run_rc" ]; then
  echo "error: could not determine VM command status; see $log" >&2
  exit 1
fi

exit "$run_rc"
