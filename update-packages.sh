#!/bin/bash

declare -a pkgs=(
  "addrman-observer"
  "fork-observer"
  "miningpool-observer"
  "peer-observer"
  "github-metadata-mirror"
  "github-metadata-backup"
  "transactionfee-info-backend"
)

for i in "${pkgs[@]}"
do
  echo "updating $i"
  nix-shell -p nix-update --run "nix-update --flake --version=branch $i"
done
