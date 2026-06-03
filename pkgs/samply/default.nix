{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "samply";
  version = "0-unstable-2026-05-13";

  src = fetchFromGitHub {
    owner = "mstange";
    repo = "samply";
    rev = "d31a3e9ed59f06d309d6984455c824a03a15f081";
    hash = "sha256-wGYN38owi5ryz9bQX5BOD7D91eYxUE9R7nsSXGIyiLM=";
  };

  cargoHash = "sha256-NFctaIv1bAnW62yE030HJRihVzidabrK3DWDZnxt3Zg=";

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
