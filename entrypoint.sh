#!/bin/bash

# rules
eval "$(grep CONFIG_TARGET_BOARD .config)"
eval "$(grep CONFIG_TARGET_SUBTARGET .config)"
export BOARD=$CONFIG_TARGET_BOARD
export SUBTARGET=$CONFIG_TARGET_SUBTARGET
export BIN_DIR=bin/targets/$BOARD/$SUBTARGET
export SCRIPT_DIR=scripts
export OPKG_KEYS=keys
export BUILD_KEY=key-build
export STAGING_DIR_HOST=staging_dir/host
alias usign="$STAGING_DIR_HOST/bin/usign"

set -ef

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
		$SCRIPT_DIR/opkg-key add <(echo "$_key" | base64 -d)
	done
fi

if [ "$SIGN" = '1' ];then
	pushd $BIN_DIR
	usign -S -m sha256sums -s $BUILD_KEY
	popd
fi
