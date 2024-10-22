{ pkgs, ... }:

let
  BITCOIND_RPC_PORT = 8332;
  MPO_DAMON_PROMETHEUS_PORT = 2482;
  MPO_WEB_PORT = 8938;
  PG_PORT = 5432;
  SANCTIONED_ADDRESS = "bcrt1qs758ursh4q9z627kt3pp5yysm78ddny6txaqgw";
  MPO_WEB_TITLE = "this-is-a-title-test";
  MPO_WEB_FOOTER = "this-is-a-footer-test";
in
{
  name = "miningpool-observer";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [ ../modules/miningpool-observer/default.nix ];

      virtualisation.cores = 1;

      services.bitcoind."regtest" = {
        enable = true;
        extraConfig = ''
          regtest=1
          rest=1
          debug=rpc
        '';
        rpc = {
          port = BITCOIND_RPC_PORT;
          users.miningpool-observer = {
            name = "miningpool-observer";
            passwordHMAC = "a086e1c71a326b56b490249203406ad6$30d91b328c812f1faf82783df5388b808b3a91a945a0f8bae071c2bef4549e7e";
          };
        };
      };

      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        settings.port = PG_PORT;
        authentication = pkgs.lib.mkOverride 10 ''
          local all all trust
          host all all ::1/128 trust
          host all all 127.0.0.1/32 trust
        '';
        ensureDatabases = [ "miningpoolobserver" ];
        ensureUsers = [
          {
            name = "miningpoolobserver";
            ensureDBOwnership = true;
          }
        ];
      };

      # a fake sanctioned addresses list so that
      # this test doesn't need to query the internet/github
      services.nginx = {
        enable = true;
        virtualHosts."localhost" = {
          listen = [
            {
              addr = "127.0.0.1";
              port = 80;
            }
          ];
          locations."/sanctioned.txt" = {
            extraConfig = ''
              return 200 '${SANCTIONED_ADDRESS}\n';
              add_header Content-Type text/plain;
            '';
          };
        };
      };

      services.miningpool-observer = {
        enable = true;
        databaseURL = "postgres://miningpoolobserver@127.0.0.1:${toString PG_PORT}/miningpoolobserver";
        bitcoindRPCUser = "miningpool-observer";
        bitcoindRPCPassword = "hunter2";
        daemonLogLevel = "debug";
        daemonPrometheusAddress = "127.0.0.1:${toString MPO_DAMON_PROMETHEUS_PORT}";

        sanctionedAddressesUrl = "http://127.0.0.1:80/sanctioned.txt";

        address = "127.0.0.1:${toString MPO_WEB_PORT}";
        siteTitle = MPO_WEB_TITLE;
        siteFooter = MPO_WEB_FOOTER;
        siteBaseURL = "127.0.0.1:${toString MPO_WEB_PORT}";
        webLogLevel = "info";
      };
    };

  testScript = ''
    import time

    machine.systemctl("stop miningpool-observer-daemon.service")
    machine.systemctl("stop miningpool-observer-web.service")

    machine.wait_for_unit("postgresql.service", timeout=15)
    machine.wait_for_open_port(${toString PG_PORT})

    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_RPC_PORT})

    # give bitcoind a bit of time to start up before we hit the RPC interface
    time.sleep(5)

    machine.systemctl("start miningpool-observer-daemon.service")
    machine.wait_for_unit("miningpool-observer-daemon.service", timeout=15)
    machine.wait_for_open_port(${toString MPO_DAMON_PROMETHEUS_PORT})

    # configuration file should have been created
    daemonconfig = machine.succeed("cat /etc/miningpool-observer/daemon-config.toml")
    print("Daemon configuration file:")
    print(daemonconfig)


    machine.systemctl("start miningpool-observer-web.service")
    machine.wait_for_unit("miningpool-observer-web.service", timeout=15)
    machine.wait_for_open_port(${toString MPO_WEB_PORT})

    # configuration file should have been created
    webconfig = machine.succeed("cat /etc/miningpool-observer/web-config.toml")
    print("web configuration file:")
    print(webconfig)

    web = machine.succeed("curl http://127.0.0.1:${toString MPO_WEB_PORT}/");
    print(web)
    assert "${MPO_WEB_TITLE}" in web
    assert "${MPO_WEB_FOOTER}" in web

    rss = machine.succeed("curl http://127.0.0.1:${toString MPO_WEB_PORT}/template-and-block/sanctioned-feed.xml");
    print(rss)
    assert "No Blocks with missing Sanctioned Transactions present in the database" in rss
        
    machine.succeed("${pkgs.postgresql}/bin/psql -U miningpoolobserver -d miningpoolobserver -c 'select * from sanctioned_addresses;' | grep ${SANCTIONED_ADDRESS}")
  '';
}
