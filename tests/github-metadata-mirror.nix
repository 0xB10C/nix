{ pkgs, ... }:

let
  backup = pkgs.fetchFromGitHub {
    owner = "bitcoin-data";
    repo = "github-metadata-backup-bitcoin-core-secp256k1";
    rev = "d572dcf7206d10ec7a40055fbcbdc9fecb5a7ca7";
    sha256 = "sha256-QGhZIrZy1VQj+s0arraL/gpC6ifT/lyh71nLAlOM6I4=";
  };
  wwwDir = "/var/www/github-metadata-mirror";
in {
  name = "github-metadata-mirror";

  nodes.machine = { config, lib, ... }: {
    imports = [ ../modules/github-metadata-mirror/default.nix ];

    virtualisation.cores = 2;
    virtualisation.memorySize = 1024;

    services.github-metadata-mirror.mirrors."secp256k1" = {
      enable = true;
      backup = "${backup}";
      siteName = "secp256k1 Mirror";
      siteBaseURL = "/";
      owner = "bitcoin-core";
      repository = "secp256k1";
    };
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.succeed("systemctl start github-metadata-mirror-secp256k1.service")

    # home page should exist and contain expected content
    machine.succeed("stat ${wwwDir}/secp256k1/index.html")
    home = machine.succeed("cat ${wwwDir}/secp256k1/index.html")
    assert "secp256k1 Mirror" in home, "site title missing from home page"
    assert "Recent Issues and PRs" in home, "expected heading missing"

    # graph data should be present
    machine.succeed("stat ${wwwDir}/secp256k1/graph.json")

    # search index should be present
    machine.succeed("stat ${wwwDir}/secp256k1/index.json")

    # at least one issue page should have been generated
    machine.succeed("find ${wwwDir}/secp256k1 -mindepth 2 -name index.html -quit")

    print("github-metadata-mirror test passed")
  '';
}
