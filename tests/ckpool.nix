{ pkgs, ... }:

let
  CKPOOL_PORT = 3333;
  BITCOIND_RPC_PORT = 8332;
in
{
  name = "ckpool";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [ ../modules/ckpool/default.nix ];

      virtualisation.cores = 2;

      services.bitcoind."regtest" = {
        enable = true;
        extraConfig = ''
          regtest=1
          debug=rpc
        '';
        rpc = {
          port = BITCOIND_RPC_PORT;
          users.ckpool = {
            name = "ckpool";
            passwordHMAC = "a086e1c71a326b56b490249203406ad6$30d91b328c812f1faf82783df5388b808b3a91a945a0f8bae071c2bef4549e7e";
          };
        };
      };

      services.ckpool = {
        enable = true;
        iam_not_using_this_to_mine = true;
        rpc = {
          user = "ckpool";
          password = "hunter2";
          port = config.services.bitcoind.regtest.rpc.port;
        };
        address = "127.0.0.1:${toString CKPOOL_PORT}";
        coinbaseAddress = "bcrt1qs758ursh4q9z627kt3pp5yysm78ddny6txaqgw";
      };
    };

  testScript = ''
    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_RPC_PORT})

    machine.wait_for_unit("ckpool.service", timeout=15)
    machine.wait_for_open_port(${toString CKPOOL_PORT})

    # connecting to ckpool is convered by the stratum-observer test
  '';
}
