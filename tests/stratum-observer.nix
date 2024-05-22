{ pkgs, ... }:

let

  CKPOOL_PORT = 3333;
  BITCOIND_RPC_PORT = 8332;
  PG_PORT = 5432;
  STRATUM_OBSERVER_WEBSOCKET_PORT = 45324;

in {
  name = "stratum-observer";

  nodes.machine = { config, lib, ... }: {
    imports =
      [ ../modules/stratum-observer/default.nix ../modules/ckpool/default.nix ];

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
          passwordHMAC =
            "a086e1c71a326b56b490249203406ad6$30d91b328c812f1faf82783df5388b808b3a91a945a0f8bae071c2bef4549e7e";
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

     services = {
      postgresql = {
        enable = true;
        enableTCPIP = true;
        settings.port = PG_PORT;
        authentication = pkgs.lib.mkOverride 10 ''
          local all all trust
          host all all ::1/128 trust
          host all all 127.0.0.1/32 trust
        '';
        ensureDatabases = [ "stratumobserver" ];
        ensureUsers = [
          {
            name = "stratumobserver";
            ensureDBOwnership = true;
          }
        ];
      };
    };

    systemd.services = {
      "stratum-observer" = {
        # wantedBy = [ "postgresql.service" ];
        after = [ "postgresql.service" "bitcoind-regtest.service" "ckpool.service" ];
      };
    };

    services.stratum-observer = {
      enable = true;
      postgresqlUrl = "postgres://stratumobserver@127.0.0.1/stratumobserver";
      websocketAddress = "0.0.0.0:${toString STRATUM_OBSERVER_WEBSOCKET_PORT}";
      pools = [{
        name = "ckpool";
        endpoint = config.services.ckpool.address;
        username = "test.1";
        password = "pw";
        maxLifetime = 20;
      }];
      logLevel = "debug";
    };
  };

  testScript = ''
    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_RPC_PORT})

    machine.wait_for_unit("ckpool.service", timeout=15)
    machine.wait_for_open_port(${toString CKPOOL_PORT})

    machine.wait_for_unit("postgresql.service", timeout=15)
    machine.wait_for_open_port(${toString PG_PORT})
    
    machine.wait_for_unit("stratum-observer.service", timeout=15)
    machine.wait_for_open_port(${toString STRATUM_OBSERVER_WEBSOCKET_PORT})

    # configuration file should have been created
    config = machine.succeed("cat /etc/stratum-observer/config.toml")
    print("Configuration file:")
    print(config)

    # check that the database table has been created
    machine.succeed("${pkgs.postgresql}/bin/psql -U stratumobserver -c 'select * from job_updates limit 0;' | grep timestamp ") 
  '';
}
