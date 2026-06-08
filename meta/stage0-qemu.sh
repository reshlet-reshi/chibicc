#!/bin/bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo_root=$(git -C "$script_dir" rev-parse --show-toplevel)

stage0_expected_head=45d90f5955b6907dc6cdea9ebafce558359edcd3
live_bootstrap_expected_head=9a268c4c39cae952b268bc86da342be2175f03d4
stage0_src=$repo_root/meta/stage0-posix
live_bootstrap_src=$repo_root/meta/live-bootstrap
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
preseed_0_tar=$cache/preseed-0.tar
preseed_0_stamp=$cache/preseed-0.stage0-head
preseed_0_src=$cache/preseed-0-src
preseed_1_tar=$cache/preseed-1.tar
preseed_1_stamp=$cache/preseed-1.stamp
preseed_1_log=$cache/preseed-1.log
preseed_1_validate_dir=$cache/preseed-1-validate
preseed_2_tar=$cache/preseed-2.tar
preseed_2_stamp=$cache/preseed-2.stamp
preseed_2_log=$cache/preseed-2.log
preseed_2_validate_dir=$cache/preseed-2-validate
live_bootstrap_manifest=$cache/live-bootstrap.manifest
live_bootstrap_sources=$cache/live-bootstrap.sources
live_bootstrap_distfiles=$cache/live-bootstrap-distfiles
success_marker=STAGE0_QEMU_SANITY_OK
live_bootstrap=0
preseed_level=0
preseed_level_set=0
preseed_level_requested=0
repl=1
build_preseed_1=0
build_preseed_2=0
capture_preseed_1=0
capture_preseed_2=0
no_preseed_requested=0
live_bootstrap_start_after=
live_bootstrap_stop_after=simple-patch-1.0
preseed_1_begin=STAGE0_PRESEED_1_TAR_BEGIN
preseed_1_end=STAGE0_PRESEED_1_TAR_END
preseed_2_begin=STAGE0_PRESEED_2_TAR_BEGIN
preseed_2_end=STAGE0_PRESEED_2_TAR_END
mes_checksums=$live_bootstrap_src/steps/mes-0.27.1/mes-0.27.1.amd64.checksums

usage() {
  cat <<EOF
usage: meta/stage0-qemu.sh [--live-bootstrap]
                           [--build-preseed-1 | --build-preseed-2]
                           [--preseed-N] [--no-preseed] [--no-repl]

Boot stage0-posix in QEMU TCG with a pinned Linux kernel and BusyBox initramfs.
By default the host builds or reuses an AMD64 preseed-0 tar, overlays it into
the guest before boot, and drops into BusyBox ash after setup. With
--no-preseed, the guest runs the AMD64 sanity seed. With --no-repl, the guest
powers off after setup. With --live-bootstrap, the guest uses a chroot-style
live-bootstrap rootfs truncated after the mes-0.27.1 build. Unless overridden,
live-bootstrap mode uses 4096M of guest RAM and a 7200-second headless timeout.
The --preseed-N flags select the highest preseed level to apply; currently
--preseed-0 and --preseed-1 are supported, and --live-bootstrap defaults to
--preseed-1. With --build-preseed-1, the guest runs the simple-patch-1.0
checkpoint headlessly, emits the built checksum-transcriber and simple-patch
binaries over serial, and stores the validated capture as preseed-1.tar. With
--build-preseed-2, the guest runs through mes-0.27.1, emits the Mes package
over serial, and stores the validated capture as preseed-2.tar. Set
STAGE0_QEMU_TIMEOUT=0 to disable the headless timeout for long manual runs.
EOF
}

parse_preseed_level() {
  local level=${1#--preseed-}

  if [[ ! $level =~ ^[0-9]+$ ]]; then
    echo "invalid preseed level: $1" >&2
    exit 1
  fi
  if ((level > 1)); then
    echo "unsupported preseed level: $level" >&2
    exit 1
  fi

  preseed_level=$level
  preseed_level_set=1
  preseed_level_requested=1
}

while (($#)); do
  case $1 in
    --live-bootstrap)
      live_bootstrap=1
      success_marker=STAGE0_LIVE_BOOTSTRAP_OK
      ;;
    --build-preseed-1)
      build_preseed_1=1
      ;;
    --build-preseed-2)
      build_preseed_2=1
      ;;
    --no-preseed)
      no_preseed_requested=1
      preseed_level=-1
      preseed_level_set=1
      ;;
    --preseed-[0-9]*)
      parse_preseed_level "$1"
      ;;
    --no-repl)
      repl=0
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

if ((build_preseed_1)) && ((build_preseed_2)); then
  echo "--build-preseed-1 cannot be combined with --build-preseed-2" >&2
  exit 1
fi

if ((build_preseed_1 || build_preseed_2)); then
  if ((no_preseed_requested)); then
    echo "--build-preseed requires preseeds; drop --no-preseed" >&2
    exit 1
  fi
  live_bootstrap=1
  preseed_level=0
  if ((build_preseed_2)); then
    preseed_level=1
  fi
  preseed_level_set=1
  repl=0
  success_marker=STAGE0_LIVE_BOOTSTRAP_OK
fi

if ((live_bootstrap)) && ((preseed_level_set == 0)); then
  preseed_level=1
fi
if ((no_preseed_requested)) && ((preseed_level_requested)); then
  echo "--no-preseed cannot be combined with --preseed-N" >&2
  exit 1
fi
if ((live_bootstrap == 0)) && ((build_preseed_1 == 0)) \
  && ((build_preseed_2 == 0)) \
  && ((preseed_level > 0))
then
  echo "--preseed-$preseed_level requires --live-bootstrap" >&2
  exit 1
fi

if ((live_bootstrap)) && [[ -z ${STAGE0_QEMU_MEMORY+x} ]]; then
  qemu_memory=4096M
fi
if ((live_bootstrap)) && [[ -z ${STAGE0_QEMU_TIMEOUT+x} ]]; then
  timeout_seconds=7200
fi

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

require_preseed_commands() {
  require_command make
}

require_live_bootstrap_commands() {
  require_command curl
}

require_preseed_1_commands() {
  require_command base64
}

require_preseed_2_commands() {
  require_command base64
}

sha256_matches() {
  local path=$1
  local expected=$2

  printf '%s  %s\n' "$expected" "$path" | sha256sum -c - >/dev/null 2>&1
}

manifest_build_name() {
  local line=$1

  if [[ $line =~ ^build:[[:space:]]+([^[:space:]#]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  fi
}

configure_live_bootstrap_manifest() {
  live_bootstrap_stop_after=mes-0.27.1
  if ((preseed_level >= 1)); then
    live_bootstrap_start_after=simple-patch-1.0
  else
    live_bootstrap_start_after=
  fi
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

prepare_live_bootstrap_submodule() {
  local actual_head

  if [[ -f $live_bootstrap_src/rootfs.py ]]; then
    actual_head=$(git -C "$live_bootstrap_src" rev-parse HEAD)
    if [[ $actual_head == "$live_bootstrap_expected_head" ]]; then
      return
    fi
  fi

  git -C "$repo_root" submodule update --init meta/live-bootstrap

  actual_head=$(git -C "$live_bootstrap_src" rev-parse HEAD)
  if [[ $actual_head != "$live_bootstrap_expected_head" ]]; then
    echo "meta/live-bootstrap is at $actual_head" >&2
    echo "expected $live_bootstrap_expected_head" >&2
    exit 1
  fi
}

copy_tree_to() {
  local destination=$2
  local source=$1

  mkdir -p "$destination"
  (
    cd "$source"
    tar --exclude=.git --exclude='*/.git' -cf - .
  ) | tar -xf - -C "$destination"
}

copy_stage0_tree_to() {
  local destination=$1

  copy_tree_to "$stage0_src" "$destination"
}

preseed_0_is_current() {
  [[ -f $preseed_0_tar ]] \
    && [[ -f $preseed_0_stamp ]] \
    && [[ $(<"$preseed_0_stamp") == "$stage0_expected_head" ]]
}

build_preseed_0_tar() {
  local stamp_tmp
  local tar_tmp

  if preseed_0_is_current; then
    echo "stage0-qemu: using current preseed-0 tar: $preseed_0_tar"
    return
  fi

  echo "stage0-qemu: building preseed-0 tar: $preseed_0_tar"
  require_preseed_commands
  tar_tmp=$preseed_0_tar.tmp
  stamp_tmp=$preseed_0_stamp.tmp
  mkdir -p "$(dirname "$tar_tmp")" "$(dirname "$stamp_tmp")"
  tar_tmp=$(cd "$(dirname "$tar_tmp")" && pwd)/$(basename "$tar_tmp")
  stamp_tmp=$(cd "$(dirname "$stamp_tmp")" && pwd)/$(basename "$stamp_tmp")
  rm -rf "$preseed_0_src"
  rm -f "$tar_tmp" "$stamp_tmp"

  copy_stage0_tree_to "$preseed_0_src"
  make -C "$preseed_0_src" test-amd64

  (
    cd "$preseed_0_src"
    tar -cf "$tar_tmp" AMD64/bin
  )
  printf '%s\n' "$stage0_expected_head" > "$stamp_tmp"
  mv "$tar_tmp" "$preseed_0_tar"
  mv "$stamp_tmp" "$preseed_0_stamp"
}

copy_stage0_tree() {
  copy_stage0_tree_to "$rootfs/stage0-posix"
}

apply_preseed() {
  if ((preseed_level < 0)); then
    return
  fi

  if ((live_bootstrap)); then
    tar -xf "$preseed_0_tar" -C "$rootfs"
    if ((preseed_level >= 1)); then
      validate_preseed_1_tar "$preseed_1_tar"
      tar -xf "$preseed_1_tar" -C "$rootfs"
    fi
  else
    tar -xf "$preseed_0_tar" -C "$rootfs/stage0-posix"
  fi
}

preseed_1_expected_sha() {
  local checksum_path=$2
  local file=$live_bootstrap_src/steps/$1/$1.amd64.checksums
  local path
  local sha

  while read -r sha path; do
    if [[ $path == "$checksum_path" ]]; then
      printf '%s\n' "$sha"
      return
    fi
  done < "$file"

  echo "stage0-qemu: missing expected checksum for $checksum_path" >&2
  exit 1
}

preseed_1_expected_stamp() {
  local checksum_transcriber_sha
  local simple_patch_sha

  checksum_transcriber_sha=$(
    preseed_1_expected_sha checksum-transcriber-1.0 \
      /usr/bin/checksum-transcriber
  )
  simple_patch_sha=$(
    preseed_1_expected_sha simple-patch-1.0 /usr/bin/simple-patch
  )

  cat <<EOF
stage0-posix=$stage0_expected_head
live-bootstrap=$live_bootstrap_expected_head
checkpoint=simple-patch-1.0
usr/bin/checksum-transcriber=$checksum_transcriber_sha
usr/bin/simple-patch=$simple_patch_sha
EOF
}

validate_preseed_1_tar() {
  local tar_path=$1
  local checksum_transcriber_sha
  local contents
  local expected_contents
  local simple_patch_sha

  expected_contents=$(printf '%s\n%s' \
    usr/bin/checksum-transcriber \
    usr/bin/simple-patch)
  contents=$(tar -tf "$tar_path" | sort)
  if [[ $contents != "$expected_contents" ]]; then
    echo "stage0-qemu: unexpected preseed-1 tar contents:" >&2
    printf '%s\n' "$contents" >&2
    return 1
  fi

  rm -rf "$preseed_1_validate_dir"
  mkdir -p "$preseed_1_validate_dir"
  tar -xf "$tar_path" -C "$preseed_1_validate_dir"

  checksum_transcriber_sha=$(
    preseed_1_expected_sha checksum-transcriber-1.0 \
      /usr/bin/checksum-transcriber
  )
  simple_patch_sha=$(
    preseed_1_expected_sha simple-patch-1.0 /usr/bin/simple-patch
  )

  if ! sha256_matches \
    "$preseed_1_validate_dir/usr/bin/checksum-transcriber" \
    "$checksum_transcriber_sha"
  then
    echo "stage0-qemu: checksum-transcriber hash mismatch" >&2
    return 1
  fi
  if ! sha256_matches \
    "$preseed_1_validate_dir/usr/bin/simple-patch" \
    "$simple_patch_sha"
  then
    echo "stage0-qemu: simple-patch hash mismatch" >&2
    return 1
  fi
}

preseed_1_is_current() {
  [[ -f $preseed_1_tar ]] \
    && [[ -f $preseed_1_stamp ]] \
    && [[ $(<"$preseed_1_stamp") == "$(preseed_1_expected_stamp)" ]] \
    && validate_preseed_1_tar "$preseed_1_tar"
}

preseed_2_expected_stamp() {
  cat <<EOF
stage0-posix=$stage0_expected_head
live-bootstrap=$live_bootstrap_expected_head
checkpoint=mes-0.27.1
checksums:
EOF
  cat "$mes_checksums"
}

validate_preseed_2_tar() {
  local contents
  local path
  local rel_path
  local sha
  local tar_path=$1

  contents=$(tar -tf "$tar_path" | sort)
  while IFS= read -r path; do
    if [[ $path == /* || $path == .. || $path == ../* \
      || $path == */.. || $path == */../* ]]
    then
      echo "stage0-qemu: unsafe preseed-2 path: $path" >&2
      return 1
    fi
    case $path in
      usr/bin/mes-m2 | \
        usr/bin/mescc.scm | \
        usr/lib/x86_64-mes/* | \
        usr/lib/linux/x86_64-mes/* | \
        usr/include/mes/*)
        ;;
      *)
        echo "stage0-qemu: unexpected preseed-2 path: $path" >&2
        return 1
        ;;
    esac
  done <<< "$contents"

  rm -rf "$preseed_2_validate_dir"
  mkdir -p "$preseed_2_validate_dir"
  tar -xf "$tar_path" -C "$preseed_2_validate_dir"

  while read -r sha path; do
    rel_path=${path#/}
    if [[ ! -f $preseed_2_validate_dir/$rel_path ]]; then
      echo "stage0-qemu: missing preseed-2 path: $rel_path" >&2
      return 1
    fi
    if ! sha256_matches "$preseed_2_validate_dir/$rel_path" "$sha"; then
      echo "stage0-qemu: preseed-2 hash mismatch: $rel_path" >&2
      return 1
    fi
  done < "$mes_checksums"
}

preseed_2_is_current() {
  [[ -f $preseed_2_tar ]] \
    && [[ -f $preseed_2_stamp ]] \
    && [[ $(<"$preseed_2_stamp") == "$(preseed_2_expected_stamp)" ]] \
    && validate_preseed_2_tar "$preseed_2_tar"
}

decode_preseed_1_capture() {
  local found_begin=0
  local found_end=0
  local in_payload=0
  local line
  local payload_tmp=$1
  local tar_tmp=$2

  : > "$payload_tmp"
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    if [[ $line == "$preseed_1_begin" ]]; then
      found_begin=1
      in_payload=1
      continue
    fi
    if [[ $line == "$preseed_1_end" ]]; then
      found_end=1
      break
    fi
    if ((in_payload)); then
      printf '%s\n' "$line" >> "$payload_tmp"
    fi
  done < "$preseed_1_log"

  if ((found_begin == 0 || found_end == 0)); then
    echo "stage0-qemu: missing preseed-1 capture in $preseed_1_log" >&2
    return 1
  fi

  base64 -d "$payload_tmp" > "$tar_tmp"
}

decode_preseed_2_capture() {
  local found_begin=0
  local found_end=0
  local in_payload=0
  local line
  local payload_tmp=$1
  local tar_tmp=$2

  : > "$payload_tmp"
  while IFS= read -r line || [[ -n $line ]]; do
    line=${line%$'\r'}
    if [[ $line == "$preseed_2_begin" ]]; then
      found_begin=1
      in_payload=1
      continue
    fi
    if [[ $line == "$preseed_2_end" ]]; then
      found_end=1
      break
    fi
    if ((in_payload)); then
      printf '%s\n' "$line" >> "$payload_tmp"
    fi
  done < "$preseed_2_log"

  if ((found_begin == 0 || found_end == 0)); then
    echo "stage0-qemu: missing preseed-2 capture in $preseed_2_log" >&2
    return 1
  fi

  base64 -d "$payload_tmp" > "$tar_tmp"
}

build_preseed_1_tar() {
  local payload_tmp=$preseed_1_tar.base64.tmp
  local saved_capture_preseed_1
  local saved_preseed_level
  local saved_qemu_log
  local saved_start_after
  local saved_stop_after
  local stamp_tmp=$preseed_1_stamp.tmp
  local tar_tmp=$preseed_1_tar.tmp

  if preseed_1_is_current; then
    echo "stage0-qemu: using current preseed-1 tar: $preseed_1_tar"
    return
  fi

  echo "stage0-qemu: building preseed-1 tar: $preseed_1_tar"
  require_preseed_1_commands
  build_preseed_0_tar
  fetch_artifact "$kernel" "$kernel_url" "$kernel_sha"
  fetch_artifact "$busybox" "$busybox_url" "$busybox_sha"

  saved_capture_preseed_1=$capture_preseed_1
  saved_preseed_level=$preseed_level
  saved_qemu_log=$qemu_log
  saved_start_after=$live_bootstrap_start_after
  saved_stop_after=$live_bootstrap_stop_after

  capture_preseed_1=1
  preseed_level=0
  qemu_log=$preseed_1_log
  live_bootstrap_start_after=
  live_bootstrap_stop_after=simple-patch-1.0

  prepare_live_bootstrap_inputs
  rm -f "$payload_tmp" "$stamp_tmp" "$tar_tmp" "$preseed_1_log"
  build_initramfs
  run_qemu

  capture_preseed_1=$saved_capture_preseed_1
  preseed_level=$saved_preseed_level
  qemu_log=$saved_qemu_log
  live_bootstrap_start_after=$saved_start_after
  live_bootstrap_stop_after=$saved_stop_after

  decode_preseed_1_capture "$payload_tmp" "$tar_tmp"
  validate_preseed_1_tar "$tar_tmp"
  preseed_1_expected_stamp > "$stamp_tmp"
  mv "$tar_tmp" "$preseed_1_tar"
  mv "$stamp_tmp" "$preseed_1_stamp"
  rm -f "$payload_tmp"
}

build_preseed_2_tar() {
  local payload_tmp=$preseed_2_tar.base64.tmp
  local saved_capture_preseed_1
  local saved_capture_preseed_2
  local saved_preseed_level
  local saved_qemu_log
  local saved_start_after
  local saved_stop_after
  local stamp_tmp=$preseed_2_stamp.tmp
  local tar_tmp=$preseed_2_tar.tmp

  if preseed_2_is_current; then
    echo "stage0-qemu: using current preseed-2 tar: $preseed_2_tar"
    return
  fi

  echo "stage0-qemu: building preseed-2 tar: $preseed_2_tar"
  require_preseed_2_commands
  build_preseed_0_tar
  build_preseed_1_tar
  fetch_artifact "$kernel" "$kernel_url" "$kernel_sha"
  fetch_artifact "$busybox" "$busybox_url" "$busybox_sha"

  saved_capture_preseed_1=$capture_preseed_1
  saved_capture_preseed_2=$capture_preseed_2
  saved_preseed_level=$preseed_level
  saved_qemu_log=$qemu_log
  saved_start_after=$live_bootstrap_start_after
  saved_stop_after=$live_bootstrap_stop_after

  capture_preseed_1=0
  capture_preseed_2=1
  preseed_level=1
  qemu_log=$preseed_2_log
  live_bootstrap_start_after=simple-patch-1.0
  live_bootstrap_stop_after=mes-0.27.1

  prepare_live_bootstrap_inputs
  rm -f "$payload_tmp" "$stamp_tmp" "$tar_tmp" "$preseed_2_log"
  build_initramfs
  run_qemu

  capture_preseed_1=$saved_capture_preseed_1
  capture_preseed_2=$saved_capture_preseed_2
  preseed_level=$saved_preseed_level
  qemu_log=$saved_qemu_log
  live_bootstrap_start_after=$saved_start_after
  live_bootstrap_stop_after=$saved_stop_after

  decode_preseed_2_capture "$payload_tmp" "$tar_tmp"
  validate_preseed_2_tar "$tar_tmp"
  preseed_2_expected_stamp > "$stamp_tmp"
  mv "$tar_tmp" "$preseed_2_tar"
  mv "$stamp_tmp" "$preseed_2_stamp"
  rm -f "$payload_tmp"
}

generate_live_bootstrap_manifest() {
  local build_name
  local found_start=0
  local found_stop=0
  local line
  local temporary=$live_bootstrap_manifest.tmp

  if [[ -z $live_bootstrap_start_after ]]; then
    found_start=1
  fi

  mkdir -p "$(dirname "$live_bootstrap_manifest")"
  rm -f "$temporary"
  : > "$temporary"

  while IFS= read -r line; do
    build_name=$(manifest_build_name "$line")
    if ((found_start == 0)); then
      if [[ $build_name == "$live_bootstrap_start_after" ]]; then
        found_start=1
      fi
      continue
    fi

    printf '%s\n' "$line" >> "$temporary"
    if [[ $build_name == "$live_bootstrap_stop_after" ]]; then
      found_stop=1
      break
    fi
  done < "$live_bootstrap_src/steps/manifest"

  if ((found_start == 0)); then
    echo "stage0-qemu: missing $live_bootstrap_start_after manifest entry" >&2
    rm -f "$temporary"
    exit 1
  fi
  if ((found_stop == 0)); then
    echo "stage0-qemu: missing $live_bootstrap_stop_after manifest entry" >&2
    rm -f "$temporary"
    exit 1
  fi

  mv "$temporary" "$live_bootstrap_manifest"
}

generate_live_bootstrap_sources() {
  local file
  local line
  local source_file
  local step
  local temporary=$live_bootstrap_sources.tmp
  local url
  local sha
  local -a fields
  local -A seen=()

  mkdir -p "$(dirname "$live_bootstrap_sources")"
  rm -f "$temporary"
  : > "$temporary"

  while IFS= read -r line; do
    if [[ ! $line =~ ^build:[[:space:]]+([^[:space:]#]+) ]]; then
      continue
    fi

    step=${BASH_REMATCH[1]}
    source_file=$live_bootstrap_src/steps/$step/sources
    if [[ ! -f $source_file ]]; then
      continue
    fi

    while IFS= read -r line; do
      [[ -n ${line//[[:space:]]/} ]] || continue
      [[ ! $line =~ ^[[:space:]]*# ]] || continue

      read -r -a fields <<< "$line"
      if [[ ${fields[0]} == "g" || ${fields[0]} == "git" ]]; then
        url=${fields[2]}
        sha=${fields[3]}
        file=${fields[4]:-$(basename "$url")}
      else
        url=${fields[1]}
        sha=${fields[2]}
        file=${fields[3]:-$(basename "$url")}
      fi

      if [[ -z ${seen["$file"]+set} ]]; then
        seen["$file"]=1
        printf '%s\t%s\t%s\n' "$sha" "$url" "$file" >> "$temporary"
      fi
    done < "$source_file"
  done < "$live_bootstrap_manifest"

  mv "$temporary" "$live_bootstrap_sources"
}

fetch_live_bootstrap_distfiles() {
  local destination
  local file
  local sha
  local temporary
  local url

  require_live_bootstrap_commands
  mkdir -p "$live_bootstrap_distfiles"

  while IFS=$'\t' read -r sha url file; do
    destination=$live_bootstrap_distfiles/$file
    if [[ -f $destination ]] && sha256_matches "$destination" "$sha"; then
      continue
    fi

    if [[ $url == "_" ]]; then
      echo "stage0-qemu: no direct URL for live-bootstrap distfile $file" >&2
      exit 1
    fi

    echo "stage0-qemu: fetching live-bootstrap distfile: $file"
    temporary=$destination.tmp
    rm -f "$temporary"
    curl -fsSL -o "$temporary" "$url"
    if ! sha256_matches "$temporary" "$sha"; then
      echo "sha256 mismatch for $url" >&2
      rm -f "$temporary"
      exit 1
    fi
    mv "$temporary" "$destination"
  done < "$live_bootstrap_sources"
}

prepare_live_bootstrap_inputs() {
  generate_live_bootstrap_manifest
  generate_live_bootstrap_sources
  fetch_live_bootstrap_distfiles
}

copy_live_bootstrap_seed() {
  (
    cd "$live_bootstrap_src/seed"
    find . -maxdepth 1 -type f -print0 \
      | tar --null -T - -cf -
  ) | tar -xf - -C "$rootfs"
}

write_live_bootstrap_config() {
  cat > "$rootfs/steps/bootstrap.cfg" <<EOF
ARCH=amd64
ARCH_DIR=AMD64
FORCE_TIMESTAMPS=False
CHROOT=True
UPDATE_CHECKSUMS=False
JOBS=1
SWAP_SIZE=0
FINAL_JOBS=1
INTERNAL_CI=False
INTERACTIVE=False
QEMU=False
BARE_METAL=False
DISK=sda1
KERNEL_BOOTSTRAP=False
BUILD_KERNELS=False
CONFIGURATOR=False
MIRRORS_LEN=0
EOF
}

copy_live_bootstrap_distfiles() {
  local file
  local sha
  local url

  mkdir -p "$rootfs/external/distfiles"
  while IFS=$'\t' read -r sha url file; do
    cp "$live_bootstrap_distfiles/$file" "$rootfs/external/distfiles/$file"
  done < "$live_bootstrap_sources"
}

copy_live_bootstrap_rootfs() {
  copy_stage0_tree_to "$rootfs"
  copy_live_bootstrap_seed
  copy_tree_to "$live_bootstrap_src/steps" "$rootfs/steps"
  cp "$live_bootstrap_manifest" "$rootfs/steps/manifest"
  write_live_bootstrap_config
  copy_live_bootstrap_distfiles
}

write_guest_config() {
  mkdir -p "$rootfs/etc"
  {
    printf 'STAGE0_LIVE_BOOTSTRAP=%s\n' "$live_bootstrap"
    printf 'STAGE0_REPL=%s\n' "$repl"
    printf 'STAGE0_SUCCESS_MARKER=%s\n' "$success_marker"
    printf 'STAGE0_CAPTURE_PRESEED_1=%s\n' "$capture_preseed_1"
    printf 'STAGE0_CAPTURE_PRESEED_2=%s\n' "$capture_preseed_2"
  } > "$rootfs/etc/stage0-qemu.conf"
}

build_initramfs() {
  rm -rf "$rootfs" "$initramfs"
  mkdir -p "$rootfs/bin" "$rootfs/dev" "$rootfs/proc" "$rootfs/sys"
  mkdir -p "$rootfs/tmp"

  install -m 0755 "$busybox" "$rootfs/bin/busybox"
  install -m 0755 "$stage0_init" "$rootfs/init"
  write_guest_config
  if ((live_bootstrap)); then
    copy_live_bootstrap_rootfs
  else
    copy_stage0_tree
  fi
  apply_preseed
  install -m 0755 "$busybox" "$rootfs/bin/busybox"
  install -m 0755 "$stage0_init" "$rootfs/init"
  write_guest_config

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
  if [[ $timeout_seconds == 0 ]]; then
    "${qemu_argv[@]}" 2>&1 | tee "$qemu_log"
    qemu_status=${PIPESTATUS[0]}
  elif command -v timeout >/dev/null 2>&1; then
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
if ((live_bootstrap)); then
  prepare_live_bootstrap_submodule
fi
if ((build_preseed_1)); then
  build_preseed_1_tar
  exit 0
fi
if ((build_preseed_2)); then
  build_preseed_2_tar
  exit 0
fi
if ((live_bootstrap)) && ((preseed_level >= 1)); then
  build_preseed_1_tar
fi
if ((live_bootstrap)); then
  configure_live_bootstrap_manifest
  prepare_live_bootstrap_inputs
fi
if ((preseed_level >= 0)); then
  build_preseed_0_tar
fi
fetch_artifact "$kernel" "$kernel_url" "$kernel_sha"
fetch_artifact "$busybox" "$busybox_url" "$busybox_sha"
build_initramfs
run_qemu
