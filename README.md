# nix - a collection of nix packages and modules

A collection of Nix modules and packages for software I've written.

<!--
![Build and populate cache](https://github.com/<YOUR-GITHUB-USER>/nur-packages/workflows/Build%20and%20populate%20cache/badge.svg)

-->
[![Cachix Cache](https://img.shields.io/badge/cachix-b10c-nixpkgs-blue.svg)](https://b10c-nixpkgs.cachix.org)

## Updating with nix-update

The [`nix-update`] tool can be used to update the version (usually commit) of the
packages. Run the following command to update, for example, miningpool-observer.

```
$ nix-update miningpool-observer --flake --version=skip
```

[`nix-update`]: https://github.com/Mic92/nix-update

## Integration tests

The integration tests can be run with `nix flake check`.
A single test, for example for `miningpool-observer`, can be run with
`nix build .#checks.x86_64-linux.miningpool-observer` on `x86_64-linux`.
Passing `--print-build-logs` helps debugging on failures.
