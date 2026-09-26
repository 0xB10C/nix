{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "samply-symbols-v0.24.1-unstable-2026-09-22";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "da48ff40a19a8df2ef0c25b96e9ae0016b5717ac";
    hash = "sha256-RstPhB/dytOhJosER2QA1DV2B0Bj0l5tVtEY6131gH4=";
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
