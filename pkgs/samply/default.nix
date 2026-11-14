{
  lib,
  rustPlatform,
  pkg-config,
  sqlite,
  zstd,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "0-unstable-2026-11-02";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "dea56099bba34dfc5da4a8c9365d90b6eabffac7";
    hash = "sha256-ydBgyohIOtbvol1TvGfse2b8adhONge4G7x68sBOda0=";
  };

  cargoHash = "sha256-pncRQ0ZCw7ZUZvxZ9mSaZA8kOrvM1oQwHAG+6eQ6K0c=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ sqlite zstd ];

  meta = {
    description = "Command line profiler for macOS and Linux";
    homepage = "https://github.com/mstange/samply";
    license = with lib.licenses; [
      asl20
      mit
    ];
    maintainers = [ ];
    mainProgram = "samply";
  };
})
