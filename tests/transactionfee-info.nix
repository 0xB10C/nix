{ pkgs, ... }:

let

  BITCOIND_REST_PORT = 8332;
  NGINX_PORT = 8000;

  frontend = (pkgs.callPackage ../. { }).transactionfee-info-frontend;
in
{
  name = "transactionfee-info";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [ ../modules/transactionfee-info/default.nix ];

      virtualisation.cores = 1;

      services.bitcoind."regtest" = {
        enable = true;
        extraConfig = ''
          regtest=1
          rest=1
        '';
        rpc = {
          port = BITCOIND_REST_PORT;
        };
      };

      services.transactionfee-info-backend = {
        enable = true;
      };

      services.nginx = {
        enable = true;
        virtualHosts."frontend" = {
          root = "${frontend}";
          listen = [
            {
              addr = "127.0.0.1";
              port = NGINX_PORT;
            }
          ];
          locations."/csv/" = {
            root = config.services.transactionfee-info-backend.csvPath;
            extraConfig = ''
              rewrite /csv/(.*) /$1  break;
            '';
          };
        };
      };
    };

  testScript = ''
    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_REST_PORT})

    machine.wait_for_unit("nginx.service", timeout=15)
    machine.wait_for_open_port(${toString NGINX_PORT})


    machine.succeed("${pkgs.bitcoind}/bin/bitcoin-cli --datadir=/var/lib/bitcoind-regtest/regtest createwallet test") 
    machine.succeed("${pkgs.bitcoind}/bin/bitcoin-cli --datadir=/var/lib/bitcoind-regtest/regtest -generate 100") 

    machine.systemctl("start transactionfee-info-backend.service")

    # check that the database table has been created
    machine.succeed("${pkgs.sqlite}/bin/sqlite3 /var/lib/transactionfee-info/db.sqlite 'select * from block_stats limit 0;'")

    # check that the database table has been created
    machine.succeed("stat /var/lib/transactionfee-info/csv/date.csv")

    # check that we can GET the index.html file 
    machine.succeed("curl --fail-with-body 127.0.0.1:8000/index.html")

    # check that we can GET charts/transactions-spending-segwit/ 
    machine.succeed("curl --fail-with-body 127.0.0.1:8000/charts/transactions-spending-segwit/")

    # check that we fail to GET bogus/url/ 
    machine.fail("curl --fail-with-body 127.0.0.1:8000/bogus/url")

    # check that we can GET the date.csv CSV file 
    machine.succeed("curl --fail-with-body 127.0.0.1:8000/csv/date.csv")

    # check that starting the service again succeeds    
    machine.systemctl("start transactionfee-info-backend.service")

    # check that the timer in listed    
    timers = str(machine.systemctl("list-timers"))
    assert ("transactionfee-info-backend.timer" in timers)
  '';
}
