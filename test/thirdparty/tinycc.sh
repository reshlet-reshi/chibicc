#!/bin/bash
repo='git@github.com:TinyCC/tinycc.git'
. test/thirdparty/common.sh.inc
git reset --hard df67d8617b7d1d03a480a28f9f901848ffbfb7ec

./configure --cc=$chibicc
$make clean
$make
$make CC=cc test
