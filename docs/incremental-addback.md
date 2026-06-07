# Incremental Add-Back Plan

## Baseline

- Branch: `32bit`
- Baseline state: clean working tree with only these local commits ahead of `origin/32bit`:
  - `bcc0834 Add test runner scripts`
  - `e421adf Add more third-party test targets`
- WIP source branch: `wip/32bit-overgrown-snapshot`
- WIP snapshot commit: `6715dd4 WIP snapshot before incremental split`

## Add-Back Order

1. Add the Alpine QEMU VM harness for core tests.
   - Restore the VM build/run scripts from the WIP snapshot.
   - Restore `.vm/` ignore handling.
   - Use `make test-all` as the initial `vm/run.sh` default.
   - Include only the minimal Alpine/musl host support needed for core tests.

2. Add offline third-party inputs and submodules.
   - Restore pinned submodules for TinyCC, libpng, and SQLite.
   - Prefer HTTPS clone URLs.
   - Add clear offline/trusted-existing behavior to `test-thirdparty.sh`.
   - Keep submodule pin validation host-side before VM boots.

3. Add third-party VM integration.
   - Let VM runs use the validated offline third-party sources.
   - Keep `make test-all` as the VM default until full third-party runs are stable.
   - Add third-party commands one target at a time.

4. Revisit GNU `__attribute__` support separately.
   - Do not restore the broad parser changes from the WIP snapshot as-is.
   - Start with a smaller design for the specific attribute forms needed by third-party tests.
   - Resolve `_Alignas` and GNU alignment interactions before re-adding aligned attribute support.

## Initial Verification Targets

- After each add-back commit:
  - `git status --short --branch`
  - `bash -n` for touched shell scripts
  - `git diff --check`
- VM harness commit:
  - `make test-all`
  - `./vm/build-image.sh`
  - `./vm/run.sh`
- Offline third-party commit:
  - `git submodule update --init --recursive`
  - `./vm/run.sh "make test-all"`
  - a bad third-party commit override must fail before QEMU boots

## Explicit Deferrals

- Full TinyCC-in-VM success is deferred until the attribute work is redesigned.
- Broad GNU ignored/unsupported attribute parsing is deferred.
- Over-aligned automatic local support is deferred unless the compiler gains stack alignment codegen for it.
