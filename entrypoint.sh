#!/bin/bash

# rules
eval "$(grep CONFIG_TARGET_BOARD .config)"
eval "$(grep CONFIG_TARGET_SUBTARGET .config)"
export BOARD=$CONFIG_TARGET_BOARD
export SUBTARGET=$CONFIG_TARGET_SUBTARGET
export TOPDIR=$(pwd)
export OUTPUT_DIR=$TOPDIR/bin
export BIN_DIR=$OUTPUT_DIR/targets/$BOARD/$SUBTARGET
export SCRIPT_DIR=$TOPDIR/scripts
export OPKG_KEYS=$TOPDIR/keys
export BUILD_KEY=$TOPDIR/key-build
export STAGING_DIR_HOST=$TOPDIR/staging_dir/host
PATHBK="$PATH"
export PATH="$STAGING_DIR_HOST/bin:$PATH"

set -ef

GROUP=

group() {
	endgroup
	echo "::group::  $1"
	GROUP=1
}

endgroup() {
	if [ -n "$GROUP" ]; then
		echo "::endgroup::"
	fi
	GROUP=
}

trap 'endgroup' ERR

for d in bin; do
	mkdir -p /artifacts/$d 2>/dev/null
	ln -s /artifacts/$d $d
done

if [ -n "$KEY_BUILD" ]; then
	echo "$KEY_BUILD" > $BUILD_KEY
	SIGN="1"
fi
if [ -n "$KEY_BUILD_PUB" ]; then
	echo "$KEY_BUILD_PUB" > $BUILD_KEY.pub
	$SCRIPT_DIR/opkg-key add $BUILD_KEY.pub
	ADD_LOCAL_KEY="1"
fi
if [ -n "$KEY_VERIFY" ]; then
	for _key in $KEY_VERIFY; do
		base64 -d <<< "$_key" > /tmp/_key
		$SCRIPT_DIR/opkg-key add /tmp/_key
	done
fi

group "ls -R $OPKG_KEYS"
ls -R $OPKG_KEYS
endgroup

regexp='src imagebuilder file:packages'

if [ -n "$NO_DEFAULT_REPOS" ]; then
	sed -i 's|^src/gz|## src/gz|g' repositories.conf
fi
if [ -z "$NO_LOCAL_REPOS" ]; then
	sed -i "/$regexp/i\\src custom file:///repo/" repositories.conf
fi
for EXTRA_REPO in $EXTRA_REPOS; do
	sed -i "/$regexp/i\\$(echo "$EXTRA_REPO" | tr '|' ' ')" repositories.conf
done
if [ -n "$NO_SIGNATURE_CHECK" ]; then
	sed -i 's|^option check_signature|## option check_signature|' repositories.conf
fi

group "repositories.conf"
cat repositories.conf
endgroup

if [ -n "$ROOTFS_SIZE" ]; then
	sed -i "s|\(\bCONFIG_TARGET_ROOTFS_PARTSIZE\)=.*|\1=$ROOTFS_SIZE|" .config
fi

RET=0

export PATH="$PATHBK"
make image \
	PROFILE="$PROFILE" \
	DISABLED_SERVICES="$DISABLED_SERVICES" \
	ADD_LOCAL_KEY="$ADD_LOCAL_KEY" \
	PACKAGES="$PACKAGES" || RET=$?

if [ "$SIGN" = '1' ];then
	pushd $BIN_DIR
	$STAGING_DIR_HOST/bin/usign -S -m sha256sums -s $BUILD_KEY
	popd
fi

exit "$RET"
