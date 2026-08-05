{ pkgs, ... }:

let

  BITCOIND_RPC_PORT = 8332;
  FORK_OBSERVER_PORT = 5432;
  DB_NAME = "nixos-test.sqlite";
  ACTIVITY_DB_NAME = "nixos-test-activity.sqlite";
  # deliberately outside /var/lib/fork-observer, to check that the module
  # creates it and makes it writable for the hardened service
  ARCHIVE_DIR = "/var/lib/fork-observer-activity-archive";
  ADDRESS = "127.0.0.1:${toString FORK_OBSERVER_PORT}";
  NETWORK_ID = 1234;
  # a throw-away regtest address to mine to
  MINING_ADDRESS = "bcrt1qs758ursh4q9z627kt3pp5yysm78ddny6txaqgw";
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
        # generatetoaddress isn't used by fork-observer, the test mines with it
        rpcwhitelist=fork-observer:getchaintips,getblockheader,getblockhash,getblock,getnetworkinfo,generatetoaddress
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
      footer = ''
        nixos-test footer
        multi-line
      '';
      rss_base_url = ADDRESS;
      activity = {
        enable = true;
        databaseName = ACTIVITY_DB_NAME;
        archiveDirectory = ARCHIVE_DIR;
        retentionDays = 90;
      };
      networks = [
        {
          id = NETWORK_ID;
          name = "nixos-test-network";
          description = ''
            a test network
            with a multi-line
            description
          '';
          minForkHeight = 0;
          maxInterestingHeights = 25;
          activityRetentionDays = 30;
          poolIdentification = {
            enable = false;
          };
          nodes = [
            {
              id = 567;
              name = "Node 567";
              description = ''
                This is a node with a
                multi-line
                description.
              '';
              rpcPort = BITCOIND_RPC_PORT;
              rpcHost = "127.0.0.1";
              rpcUser = "fork-observer";
              rpcPassword = "hunter2";
              useREST = true;
              implementation = "BitcoinCore";
              # the only node opting into the activity log
              activityLog = true;
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
            {
              id = 570;
              name = "electrum";
              description = "This is an electrum node.";
              rpcPort = 12347;
              rpcHost = "127.0.0.1";
              useREST = false;
              implementation = "electrum";
            }
            {
              id = 571;
              name = "mempool.space";
              description = "This is using the mempool.space backend";
              rpcHost = "https://mempool.example.com/api";
              useREST = true;
              implementation = "mempoolspace";
            }
            {
              id = 572;
              name = "block-dn";
              description = "This is using the block-dn backend";
              rpcHost = "https://block-dn.example.com";
              useREST = true;
              implementation = "block-dn";
            }
          ];
          forkObservers = [{
            name = "remote fork-observer";
            description = "another fork-observer instance";
            url = "https://fork-observer.example.com";
            networkId = 1;
            nodeIdOffset = 1000;
          }];
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
    assert network["description"] == """  a test network
    with a multi-line
    description
    """

    data = machine.succeed("curl ${ADDRESS}/api/${toString NETWORK_ID}/data.json");
    print("data.json response:", data)
    d = json.loads(data)

    # the remote fork-observer is unreachable in the test, so only the locally
    # configured nodes show up here
    assert len(d["nodes"]) == 6
    node = d["nodes"][0]
    assert node["id"] == 567
    assert node["name"] == "Node 567"
    assert node["description"] == """  This is a node with a
    multi-line
    description.
    """
    assert node["implementation"] == "Bitcoin Core"
    assert node["reachable"]
    assert "Satoshi" in node["version"]

    # --- activity log ---

    # the module renders the [activity] section and the opt-ins
    assert "[activity]" in config
    assert 'database_path = "/var/lib/fork-observer/${ACTIVITY_DB_NAME}"' in config
    assert 'archive_directory = "${ARCHIVE_DIR}"' in config
    assert "retention_days = 90" in config
    assert "activity_retention_days = 30" in config
    # only node 567 opted in
    assert config.count("activity_log = true") == 1
    assert config.count("activity_log = false") == 5

    # the archive directory is created outside the state directory and the
    # module punches it through the ProtectSystem=strict sandbox
    machine.succeed("test -d ${ARCHIVE_DIR}")
    assert machine.succeed("stat -c '%U:%G' ${ARCHIVE_DIR}").strip() == "forkobserver:forkobserver"
    read_write_paths = machine.succeed("systemctl show fork-observer --property=ReadWritePaths")
    print(read_write_paths)
    assert "${ARCHIVE_DIR}" in read_write_paths

    # the activity log lives in its own database, with its own schema
    machine.succeed("${pkgs.sqlite}/bin/sqlite3 /var/lib/fork-observer/${ACTIVITY_DB_NAME} 'select * from activity limit 1;'")

    def activity_events(**params):
        query = "&".join(f"{k}={v}" for k, v in params.items())
        url = "${ADDRESS}/api/${toString NETWORK_ID}/activity.json"
        if query:
            url += "?" + query
        return json.loads(machine.succeed(f"curl {url}"))["events"]

    def wait_for_event(kind, timeout=60):
        for _ in range(timeout):
            events = activity_events()
            matching = [e for e in events if e["kind"] == kind]
            if matching:
                return matching[0]
            time.sleep(1)
        raise Exception(f"no '{kind}' event in the activity log: {activity_events()}")

    # detecting the node's version is the first thing that gets logged
    version_event = wait_for_event("node-version-changed")
    print("node-version-changed event:", version_event)
    assert version_event["node_id"] == 567
    assert version_event["details"]["old"] is None
    assert "Satoshi" in version_event["details"]["new"]

    # The first poll of a node only establishes its tips, it doesn't log an
    # event. Wait for it, so that mining is guaranteed to be a tip *change*.
    def node_567_tips():
        d = json.loads(machine.succeed("curl ${ADDRESS}/api/${toString NETWORK_ID}/data.json"))
        return [n for n in d["nodes"] if n["id"] == 567][0]["tips"]

    for _ in range(60):
        if node_567_tips():
            break
        time.sleep(1)
    else:
        raise Exception("node 567 never reported a tip")

    machine.succeed("${pkgs.bitcoind}/bin/bitcoin-cli --regtest -rpcport=${toString BITCOIND_RPC_PORT} --rpcuser=fork-observer --rpcpassword=hunter2 generatetoaddress 3 ${MINING_ADDRESS}")

    tip_event = wait_for_event("active-tip-changed")
    print("active-tip-changed event:", tip_event)
    assert tip_event["node_id"] == 567
    assert tip_event["details"]["old_height"] == 0
    assert tip_event["details"]["new_height"] == 3

    # nodes that didn't opt in are not logged
    events = activity_events()
    assert {e["node_id"] for e in events} == {567}

    # count caps the response, before pages further into the past
    assert len(activity_events(count=1)) == 1
    newest = events[0]["id"]
    assert all(e["id"] < newest for e in activity_events(before=newest))

    # the events are persisted, not only cached in memory
    kinds = machine.succeed("${pkgs.sqlite}/bin/sqlite3 /var/lib/fork-observer/${ACTIVITY_DB_NAME} 'select distinct kind from activity where network = ${toString NETWORK_ID};'")
    print("logged event kinds:", kinds)
    assert "node-version-changed" in kinds
    assert "active-tip-changed" in kinds

    # the pages showing the log are served
    machine.succeed("curl --fail ${ADDRESS}/activity > /dev/null")
    machine.succeed("curl --fail ${ADDRESS}/playback > /dev/null")
  '';
}
