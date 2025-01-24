{ pkgs, ... }:

let

  BITCOIND_RPC_PORT = 8332;
  FORK_OBSERVER_PORT = 5432;
  DB_NAME = "nixos-test.sqlite";
  ADDRESS = "127.0.0.1:${toString FORK_OBSERVER_PORT}";
  NETWORK_ID = 1234;
in {
  name = "fork-observer";

  nodes.machine = { config, lib, ... }: {
    imports =
      [ ../modules/fork-observer/default.nix ];

    virtualisation.cores = 2;

    services.bitcoind."regtest" = {
      enable = true;
      extraConfig = ''
        regtest=1
        rest=1
        debug=rpc
        rpcwhitelist=fork-observer:getchaintips,getblockheader,getblockhash,getblock,getnetworkinfo
      '';
      rpc = {
        port = BITCOIND_RPC_PORT;
        users.fork-observer = {
          name = "fork-observer";
          passwordHMAC =
            "a086e1c71a326b56b490249203406ad6$30d91b328c812f1faf82783df5388b808b3a91a945a0f8bae071c2bef4549e7e";
        };
      };
    };

    services.fork-observer = {
      enable = true;
      databaseName = DB_NAME;
      queryInterval = 2;
      footer = "nixos-test footer";
      rss_base_url = ADDRESS;
      networks = [
        {
          id = NETWORK_ID;
          name = "nixos-test-network";
          description = "a test network";
          minForkHeight = 0;
          maxInterestingHeights = 25;
          poolIdentification = {
            enable = false;
          };
          nodes = [
            {
              id = 567;
              name = "Node 567";
              description = "This is a node.";
              rpcPort = BITCOIND_RPC_PORT;
              rpcHost = "127.0.0.1";
              rpcUser = "fork-observer";
              rpcPassword = "hunter2";
              useREST = true;
              implementation = "BitcoinCore";
            }
            {
              id = 568;
              name = "esplora";
              description = "This is using the esplora backend";
              rpcPort = BITCOIND_RPC_PORT;
              rpcHost = "https://esplora.example.com/api";
              useREST = true;
              implementation = "esplora";
            }
            {
              id = 569;
              name = "btcd";
              description = "This is a btcd node.";
              rpcPort = 12345;
              rpcHost = "127.0.0.1";
              rpcUser = "fork-observer";
              rpcPassword = "hunter2";
              useREST = false;
              implementation = "btcd";
            }
          ];
        }
      ];
      address = ADDRESS;
    };

  };

  testScript = ''
    import time
    import json
    
    machine.systemctl("stop fork-observer.service")
    
    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_RPC_PORT})
  

    # give bitcoind a bit of time to start up before we hit the RPC interface
    time.sleep(5)
    machine.systemctl("start fork-observer.service")
    
    # configuration file should have been created
    config = machine.succeed("cat /etc/fork-observer/config.toml")
    print("Configuration file:")
    print(config)
    
    machine.wait_for_unit("fork-observer.service", timeout=15)
    machine.wait_for_open_port(${toString FORK_OBSERVER_PORT})

    # check that the database and the table has been created
    machine.succeed("${pkgs.sqlite}/bin/sqlite3 /var/lib/fork-observer/${DB_NAME} 'select * from headers limit 1;'")

    networks = machine.succeed("curl ${ADDRESS}/api/networks.json");
    print("networks.json response", networks)
    n = json.loads(networks)
    
    assert len(n["networks"]) == 1
    network = n["networks"][0]
    assert network["id"] == ${toString NETWORK_ID}
    assert network["name"] == "nixos-test-network"
    assert network["description"] == "a test network"

    data = machine.succeed("curl ${ADDRESS}/api/${toString NETWORK_ID}/data.json");
    print("data.json response:", data)
    d = json.loads(data)

    assert len(d["nodes"]) == 3
    node = d["nodes"][0]
    assert node["id"] == 567
    assert node["name"] == "Node 567"
    assert node["description"] == "This is a node."
    assert node["implementation"] == "Bitcoin Core"
    assert node["reachable"]
    assert "Satoshi" in node["version"]
  '';
}
