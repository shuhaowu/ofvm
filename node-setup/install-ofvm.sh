#!/bin/bash

# usage: install-ofvm.sh [system]

OFVM_BASE=$HOME/.ofvm
PROFILE_PATH=$HOME/.profile

if [ "$1" = "system" ]; then
  OFVM_BASE=/opt/ofvm
  PROFILE_PATH=/etc/profile.d/ofvm.sh
  echo "Installing to system level"
fi

set -xe
git clone https://github.com/shuhaowu/ofvm.git $OFVM_BASE

echo "if [ -f '$OFVM_BASE/ofvm.bash' ]; then" >> $PROFILE_PATH
echo "  source $OFVM_BASE/ofvm.bash"          >> $PROFILE_PATH
echo "fi"                                     >> $PROFILE_PATH

source $OFVM_BASE/ofvm.bash
