{ pkgs, ... }:

let

  BITCOIND_RPC_PORT = 34283;
  ADDRMAN_OBSERVER_PORT = 23427;
  ADDRESS = "127.0.0.1:${toString ADDRMAN_OBSERVER_PORT}";
in
{
  name = "addrman-observer";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [ ../modules/addrman-observer/default.nix ];

      virtualisation.cores = 1;

      services.bitcoind."regtest" = {
        enable = true;
        extraConfig = ''
          regtest=1
          rest=1
          debug=rpc
          rpcwhitelist=addrman-observer:getrawaddrman,addpeeraddress
        '';
        rpc = {
          port = BITCOIND_RPC_PORT;
          users.addrman-observer = {
            name = "addrman-observer";
            passwordHMAC = "a086e1c71a326b56b490249203406ad6$30d91b328c812f1faf82783df5388b808b3a91a945a0f8bae071c2bef4549e7e";
          };
        };
      };

      services.addrman-observer-proxy = {
        enable = true;
        address = ADDRESS;
        nodes = [
          {
            id = 2;
            name = "node2";
            rpc = {
              port = BITCOIND_RPC_PORT;
              host = "127.0.0.1";
              user = "addrman-observer";
              password = "hunter2";
            };
          }
        ];
      };

    };

  testScript = ''
    import time

    machine.systemctl("stop addrman-observer-proxy.service")

    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_RPC_PORT})


    # give bitcoind a bit of time to start up before we hit the RPC interface
    time.sleep(5)
    machine.systemctl("start addrman-observer-proxy.service")

    # configuration file should have been created
    config = machine.succeed("cat /etc/addrman-observer-proxy/config.toml")
    print("Configuration file:")
    print(config)

    machine.wait_for_unit("addrman-observer-proxy.service", timeout=15)
    machine.wait_for_open_port(${toString ADDRMAN_OBSERVER_PORT})

    # we expect the proxy to figure out which node we want to get both
    # via the name and the id
    result1 = machine.succeed("curl --compressed ${ADDRESS}/2");
    print("result1:", result1)
    result2 = machine.succeed("curl --compressed ${ADDRESS}/node2");
    print("result2:", result2)
    assert(result1 == result2)
    assert(result1 == "{\"new\":{},\"tried\":{}}")


    added = machine.succeed("${pkgs.bitcoind}/bin/bitcoin-cli --rpcport=${toString BITCOIND_RPC_PORT} --rpcuser=addrman-observer --rpcpassword=hunter2 addpeeraddress 1.1.1.1 1234");
    print("added", result1)

    result3 = machine.succeed("curl --compressed ${ADDRESS}/2");
    print("result3", result3)
    assert(result3 != "{\"new\":{},\"tried\":{}}")

  '';
}
