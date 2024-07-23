#!/bin/bash

declare -a pkgs=(
  "addrman-observer"
  "fork-observer"
  "miningpool-observer"
  "peer-observer"
  "github-metadata-mirror"
  "github-metadata-backup"
)

for i in "${pkgs[@]}"
do
  echo "updating $i"
  nix-update --flake --version=skip $i
done
