# `test/thirdparty/common.sh.inc`

Source: `test/thirdparty/common.sh.inc`
Status: Needs fix

Shared third-party build setup requires each caller to set `repo` and
`CHIBICC` before sourcing this file. It normalizes `CHIBICC` to an absolute
path and exposes that value as the lowercase `chibicc` variable used by the
individual package scripts.

Checkout helper should validate standalone Git checkouts before destructive
`git reset --hard`.
