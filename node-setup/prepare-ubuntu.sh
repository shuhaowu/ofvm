#!/bin/bash

set -xe

apt-get update
apt-get -y upgrade

apt-get -y install \
  tmux \
  moreutils \
  bison \
  build-essential \
  cmake \
  flex \
  git-core \
  libboost-system-dev \
  libboost-thread-dev \
  libncurses-dev \
  libopenmpi-dev \
  libreadline-dev \
  libxt-dev \
  openmpi-bin \
  zlib1g-dev

