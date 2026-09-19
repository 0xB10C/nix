{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-09-16";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "1ff6a85fa855011a3917e2b607a2d48e06e23e50";
    hash = "sha256-A1VPyRF0rv2S/fg1Qkh1UBA4F9KA1oqKXN4SwBwWDsc=";
  };

  cargoHash = "sha256-6oVURNVZI7Bw8y4R8Xn/+EHibQQ1nMrM/xzWhq7baZk=";

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
