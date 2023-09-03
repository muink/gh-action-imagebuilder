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
