{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).fork-observer;
  cfg = config.services.fork-observer;
  hardening = import ../hardening.nix;

  networkOpts = {
    options = {
      id = mkOption {
        type = types.int;
        description =
          "ID of the network as u32. Can, for example, be the network magic bytes.";
      };

      name = mkOption {
        type = types.str;
        default = "${name}";
        description = "Name of the network.";
      };

      slug = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "mainnet";
        description =
          "URL-friendly identifier used for friendly URLs like /mainnet and ?network=mainnet. Must be unique across networks. Derived from the name when unset.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Description of the network.";
      };

      countdown = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            height = mkOption {
              type = types.int;
              description = "Target block height to count down to.";
            };
            label = mkOption {
              type = types.str;
              example = "Halving";
              description = "Label shown in the frontend for the countdown.";
            };
          };
        });
        default = null;
        description =
          "Optional countdown to a specific block height, shown in the frontend. At most one per network.";
      };

      minForkHeight = mkOption {
        type = types.int;
        default = 0;
        description = "Minimum fork height to consider.";
      };

      maxInterestingHeights = mkOption {
        type = types.int;
        default = 25;
        description = "Maximum number of recent headers to serve via the API.";
      };

      nodes = mkOption {
        type = types.listOf (types.submodule nodeOpts);
        default = [ ];
        description =
          "Specification of one or more networks with nodes to connect to.";
      };

      forkObservers = mkOption {
        type = types.listOf (types.submodule forkObserverOpts);
        default = [ ];
        description = ''
          Other fork-observer instances to import nodes and headers from. The
          remote data is fetched via the remote's HTTP API every queryInterval
          seconds and merged into this network's header tree, where the remote
          nodes show up next to the locally configured ones.

          Only import from an instance trusted as much as one of your own
          nodes: imported headers are checked to hash to the block hash the
          remote reports, but heights and miners are taken at face value and
          are written to the local database permanently.
        '';
      };

      poolIdentification = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Enables the pool identification for this network";
        };

        network = mkOption {
          type = types.enum ["Mainnet" "Testnet" "Signet" "Regtest" ];
          default = "Mainnet";
          description = "Bitcoin Network used for the mining pool identification";
        };
      };
    };
  };

  makeNetworkConfig = network: ''
    [[networks]]
    id = ${toString network.id}
    name = "${network.name}"
    ${optionalString (network.slug != null) ''slug = "${network.slug}"''}
    description = """
      ${network.description}\
    """
    min_fork_height = ${toString network.minForkHeight}
    max_interesting_heights = ${toString network.maxInterestingHeights}
    [networks.pool_identification]
      enable = ${boolToString network.poolIdentification.enable}
      network = "${toString network.poolIdentification.network}"
    ${optionalString (network.countdown != null) ''
      [networks.countdown]
        height = ${toString network.countdown.height}
        label = "${network.countdown.label}"''}

    ${concatMapStrings makeNodeConfig network.nodes}
    ${concatMapStrings makeForkObserverConfig network.forkObservers}
  '';

  forkObserverOpts = {
    options = {
      name = mkOption {
        type = types.str;
        example = "b10c's observer";
        description = "Name of the remote fork-observer instance.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Description of the remote fork-observer instance.";
      };

      url = mkOption {
        type = types.str;
        example = "https://fork-observer.example.com";
        description = "Base URL of the remote fork-observer instance.";
      };

      networkId = mkOption {
        type = types.int;
        description =
          "ID of the network to fetch on the remote instance. This is the network id as configured there, not necessarily the local one.";
      };

      nodeIdOffset = mkOption {
        type = types.int;
        example = 1000;
        description =
          "Added to the remote node ids to avoid collisions with local node ids. Must be unique per remote instance and larger than every node id used in this network.";
      };
    };
  };

  makeForkObserverConfig = forkObserver: ''

    [[networks.forkobservers]]
    name = "${forkObserver.name}"
    description = """
      ${forkObserver.description}\
    """
    url = "${forkObserver.url}"
    network_id = ${toString forkObserver.networkId}
    node_id_offset = ${toString forkObserver.nodeIdOffset}

  '';

  nodeOpts = {
    options = {
      id = mkOption {
        type = types.int;
        description = "ID of the node as u8.";
      };

      name = mkOption {
        type = types.str;
        default = "${name}";
        description = "Name of the node.";
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = "Description of the node.";
      };

      rpcPort = mkOption {
        type = types.port;
        default = 8332;
        description = "Bitcoin Core RPC server port";
      };

      rpcHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bitcoin Core RPC server host";
      };

      rpcUser = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bitcoin Core RPC server user";
      };

      rpcPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Bitcoin Core RPC server password";
      };

      rpcCookieFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/lib/bitcoind/.cookie";
        description =
          "Bitcoin Core RPC cookie file. Mutually exclusive with rpcUser/rpcPassword.";
      };

      useREST = mkOption {
        type = types.bool;
        default = true;
        description =
          "If the Bitcoin Core REST interface should be used (otherwise slower RPC will be used).";
      };

      useWaitForNewBlock = mkOption {
        type = types.bool;
        default = true;
        description =
          "React to new blocks via Bitcoin Core's waitfornewblock RPC long-poll instead of polling every queryInterval seconds. Set to false if waitfornewblock is not on the RPC whitelist, or if a reverse proxy in front of the node kills long-held connections. Only relevant for BitcoinCore.";
      };

      implementation = mkOption {
        type = types.enum [
          "BitcoinCore"
          "btcd"
          "esplora"
          "electrum"
          "mempoolspace"
          "block-dn"
        ];
        default = "BitcoinCore";
        description = ''
          The Bitcoin implementation to query.

          The esplora, electrum and block-dn backends only ever report the
          active tip, and mempoolspace can't reconstruct fork history on its
          own. Only add these to a network that already has at least one
          BitcoinCore (or btcd) node.

          For esplora, mempoolspace and block-dn, set rpcHost to the full API
          URL (e.g. "https://mempool.space/api" or "https://block-dn.org");
          rpcPort is unused.
        '';
      };

    };
  };

  makeNodeConfig = node: ''

    [[networks.nodes]]
    id = ${toString node.id}
    name = "${node.name}"
    description = """
      ${node.description}\
    """
    rpc_host = "${node.rpcHost}"
    rpc_port = ${toString node.rpcPort}
    ${optionalString (node.rpcCookieFile != null) "rpc_cookie_file = \"${node.rpcCookieFile}\""}
    ${optionalString (node.rpcUser != null) "rpc_user = \"${node.rpcUser}\""}
    ${optionalString (node.rpcPassword != null) "rpc_password = \"${node.rpcPassword}\""}
    use_rest = ${boolToString node.useREST}
    use_waitfornewblock = ${boolToString node.useWaitForNewBlock}
    implementation = "${node.implementation}"

  '';
in {
  options = {

    services.fork-observer = {
      enable = mkEnableOption "fork-observer";

      package = mkOption {
        type = types.package;
        default = pkg;
        defaultText = "pkgs.fork-observer";
        description = "The fork-observer package to use.";
      };

      databaseName = mkOption {
        type = types.str;
        default = "db";
        example = "db";
        description = "Name of the sqlite database.";
      };

      queryInterval = mkOption {
        type = types.int;
        default = 10;
        description =
          "Second interval for checking for new blocks. For Bitcoin Core nodes using waitfornewblock this is the maximum time between checks (the node reacts to new blocks almost immediately and only falls back to this as an upper bound); for all other backends it is the fixed polling interval.";
      };

      address = mkOption {
        type = types.str;
        default = "127.0.0.1:8080";
        description = "Address the web-server listens on";
      };

      rss_base_url = mkOption {
        type = types.str;
        default = null;
        example = "https://fork-obserser.example.com";
        description = "Base URL of the RSS server. Needed for RSS-spec valid RSS feeds.";
      };

      networks = mkOption {
        type = types.listOf (types.submodule networkOpts);
        default = [ ];
        description =
          "Specification of one or more networks with nodes to connect to.";
      };

      footer = mkOption {
        type = types.str;
        default = ''
          <div class="my-2">
            <div>
              <span class="text-muted">This site is hosted by</span>
              <br>
              <!-- uncomment this -->
              <!-- span>YOUR NAME / PSEUDONYM</span-->
              <!--remove this-->
              <span class="badge bg-danger">FIXME: PLACEHOLDER in config.toml</span>
            </div>
          </div>
        '';
        description = "Custom HTML footer";
      };

    };
  };

  config = mkIf cfg.enable {
    # The same constraints fork-observer checks at startup. Catching them here
    # turns a crash-looping service into an evaluation error.
    assertions = concatMap (network:
      let
        maxNodeId = foldl' max 0 (map (node: node.id) network.nodes);
        offsets = map (fo: fo.nodeIdOffset) network.forkObservers;
      in (map (fo: {
        assertion = fo.nodeIdOffset > maxNodeId;
        message =
          "services.fork-observer: the remote fork-observer '${fo.name}' of network '${network.name}' has a nodeIdOffset of ${
            toString fo.nodeIdOffset
          } - it must be larger than every node id in this network (the largest is ${
            toString maxNodeId
          }) to avoid id collisions.";
      }) network.forkObservers) ++ [{
        assertion = offsets == unique offsets;
        message =
          "services.fork-observer: the remote fork-observers of network '${network.name}' must have unique nodeIdOffset values.";
      }]) cfg.networks;

    users = {
      users.forkobserver = {
        isSystemUser = true;
        group = "forkobserver";
        home = "/var/lib/forkobserver";
      };
      groups.forkobserver = { };

    };

    systemd.tmpfiles.rules =
      [ "d '/var/lib/fork-observer/' 0770 'forkobserver' 'forkobserver' - -" ];

    systemd.services.fork-observer = {
      description = "fork-observer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitIntervalSec = 120;
      preStart = ''
        cat <<EOF > /etc/fork-observer/config.toml
        # fork-observer configuration file

        database_path = "/var/lib/fork-observer/${cfg.databaseName}"
        www_path = "${cfg.package}/www"
        query_interval = ${toString cfg.queryInterval}
        address = "${cfg.address}"
        rss_base_url = "${cfg.rss_base_url}"
        footer_html = """
        ${cfg.footer}
        """
        ${concatMapStrings makeNetworkConfig cfg.networks}

        EOF'';

      serviceConfig = hardening.default //
        # fork-observer connects to local and non-local IP addresses
        # e.g. esplora APIs
        hardening.allowAllIPAddresses
        // {
        ExecStart = "${cfg.package}/bin/fork-observer";
        Environment =
          "CONFIG_FILE=/etc/fork-observer/config.toml RUST_LOG=info";
        Restart = "always";
        # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
        RestartSec = 30;
        StartLimitBurst = 3;
        PermissionsStartOnly = true;
        MemoryDenyWriteExecute = true;
        ConfigurationDirectory = "fork-observer"; # /etc/fork-observer
        ConfigurationDirectoryMode = 710;
        ReadWriteDirectories = "/var/lib/fork-observer";
        DynamicUser = true;
        User = "forkobserver";
        Group = "forkobserver";
      };
    };
  };
}
