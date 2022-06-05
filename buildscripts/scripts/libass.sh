#!/bin/bash

# The shebang line isn't standardised and may not always accept arguments, or accept only one
set -e

. ../../include/path.sh

set -x # just for debug

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255 # Many shells reserve values > 126; something lower would be better.
fi



[ -f configure ] || ./autogen.sh

mkdir -p _build$ndk_suffix
cd _build$ndk_suffix

printenv | grep -E 'AR|CC|LD|RANLIB|STRIP'
# Match Meson crossfile and additionally set ranlib (supposedly unused by meson,
#  see: https://github.com/mesonbuild/meson/issues/4138#issuecomment-419253153 )
export AR="llvm-ar"
export RANLIB="llvm-ranlib"
# Below can be autodetected by autotoconf as they follow the expected naming scheme
export LD="$ndk_triple-ld" STRIP="$ndk_triple-strip"

# Just set prefix instead of DESTDIR; since it's enforced flat via symlinks anyway no need to append /usr/local
#
# Since some time, PIC is supported with ix86; can prob use assembly on Android with --with-pic (untested)
../configure \
	--host=$ndk_triple \
	--prefix="$prefix_dir" \
	--with-pic \
	--enable-static --disable-shared \
	--disable-require-system-font-provider

# merged -j toggle and argument (e.g. -j8) is a non-POSIX extension not universally supported
make -j "$cores"
make install
