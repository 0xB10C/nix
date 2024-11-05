{ pkgs, ... }:

let

  asmapTool = pkgs.stdenv.mkDerivation rec {
    name = "asmap-tool";

    # from 2024-06-27:
    version = "5215c925d1382e71c9e1d642fced8a152c629c7f";
    src = pkgs.fetchFromGitHub {
      owner = "bitcoin";
      repo = "bitcoin";
      rev = version;
      sha256 = "sha256-etzZanlqFcsKJ5mlAwvB4xQuB52qV4+qsFpsCvRfA9g=";
    };

    installPhase = ''
      cp -r $src/contrib/asmap/ $out
    '';

    meta = {
      description = "Bitcoin Core's asmap-tool";
    };
  };

  asmapData = (pkgs.callPackage ./.. { }).asmap-data;
in
{
  name = "asmap-data";

  nodes.machine =
    { config, lib, ... }:
    {
      virtualisation.cores = 1;
    };

  testScript = ''
    print("encoding & decoding asmap data (${asmapData}).. this might take a while")
    result = machine.succeed("${pkgs.python3}/bin/python ${asmapTool}/asmap-tool.py decode ${asmapData} output.txt");
    result = machine.succeed("${pkgs.python3}/bin/python ${asmapTool}/asmap-tool.py encode output.txt output.dat");

    hash_expected = machine.succeed("sha256sum ${asmapData}").split(" ")[0] 
    hash_got = machine.succeed("sha256sum output.dat").split(" ")[0]
    print("expected hash", hash_expected)
    print("got hash", hash_got)
    assert hash_expected == hash_got

  '';
}
