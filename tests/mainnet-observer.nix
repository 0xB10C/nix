{ pkgs, ... }:

let

  BITCOIND_REST_PORT = 8332;
  NGINX_PORT = 8000;

  TITLE = "test-mainnet-observer8333";
  TOP_RIGHT = "TOP_RIGHT1234";
  BOTTOM_RIGHT = "BOTTOM_RIGHT1337";
  frontend = (pkgs.callPackage ../pkgs/mainnet-observer { }).frontend { title = TITLE; baseURL = "URL_PLACEHOLDER"; htmlTopRight = TOP_RIGHT; htmlBottomRight = BOTTOM_RIGHT; };
in
{
  name = "mainnet-observer";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [ ../modules/mainnet-observer/default.nix ];

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

      services.mainnet-observer-backend = {
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
            root = config.services.mainnet-observer-backend.csvPath;
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

    machine.systemctl("start mainnet-observer-backend.service")

    # check that the database table has been created
    machine.succeed("${pkgs.sqlite}/bin/sqlite3 /var/lib/mainnet-observer/db.sqlite 'select * from block_stats limit 0;'")

    # check that the database table has been created
    machine.succeed("stat /var/lib/mainnet-observer/csv/date.csv")

    # check that we can GET the index.html file
    index = machine.succeed("curl --fail-with-body 127.0.0.1:8000/index.html")
    assert ("${TITLE}" in index)
    assert ("${TOP_RIGHT}" in index)
    assert ("${BOTTOM_RIGHT}" in index)

    # check that we can GET charts/transactions-spending-segwit/
    machine.succeed("curl --fail-with-body 127.0.0.1:8000/charts/transactions-spending-segwit/")

    # check that we fail to GET bogus/url/
    machine.fail("curl --fail-with-body 127.0.0.1:8000/bogus/url")

    # check that we can GET the date.csv CSV file
    machine.succeed("curl --fail-with-body 127.0.0.1:8000/csv/date.csv")

    # check that starting the service again succeeds
    machine.systemctl("start mainnet-observer-backend.service")

    # check that the timer in listed
    timers = str(machine.systemctl("list-timers"))
    assert ("mainnet-observer-backend.timer" in timers)
  '';
}
