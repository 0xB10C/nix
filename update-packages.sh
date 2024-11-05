#!/bin/bash

pkgs=($(nix flake show --json | jq '.packages."x86_64-linux" | keys[] ' | grep -v bitcoind-tracing))
for i in "${pkgs[@]}"
do
  echo "trying to update package: '$i'"
  nix-shell -p nix-update --run "nix-update --flake --commit --build --version=branch $i"
  git restore pkgs/
done
git log -1
