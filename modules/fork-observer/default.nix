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

      activityRetentionDays = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 30;
        description = ''
          Overrides services.fork-observer.activity.retentionDays for this
          network. Only relevant when the activity log is enabled.
        '';
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
    ${optionalString (network.activityRetentionDays != null)
    "activity_retention_days = ${toString network.activityRetentionDays}"}
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

      activityLog = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Record this node's events (tip changes, reorgs, reachability and
          version changes, ...) in the activity log. Requires
          services.fork-observer.activity.enable; without it the node opts in
          to nothing and fork-observer logs a warning at startup.
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
    activity_log = ${boolToString node.activityLog}

  '';

  makeActivityConfig = optionalString cfg.activity.enable ''
    [activity]
    database_path = "/var/lib/fork-observer/${cfg.activity.databaseName}"
    ${optionalString (cfg.activity.archiveDirectory != null)
    ''archive_directory = "${cfg.activity.archiveDirectory}"''}
    ${optionalString (cfg.activity.retentionDays != null)
    "retention_days = ${toString cfg.activity.retentionDays}"}
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

      activity = {
        enable = mkEnableOption ''
          the activity log, a timestamped per-node log of e.g. tip changes,
          reorgs, new fork tips, invalid blocks and reachability changes. It
          lives in its own sqlite database and is served via
          /api/<network_id>/activity.json and the /activity and /playback
          pages. Nodes opt in individually with activityLog = true'';

        databaseName = mkOption {
          type = types.str;
          default = "activity.sqlite";
          description = ''
            Name of the activity log sqlite database in
            /var/lib/fork-observer. Separate from databaseName, which holds
            the headers.
          '';
        };

        archiveDirectory = mkOption {
          type = types.nullOr types.path;
          default = null;
          example = "/var/lib/fork-observer/activity-archive";
          description = ''
            Directory the retention task writes monthly archive files
            (activity-archive-YYYY-MM.sqlite) to before purging the archived
            events from the live database. Required as soon as a retention is
            configured, so that a retention never deletes events without
            keeping a copy. The directory is created if it does not exist.
          '';
        };

        retentionDays = mkOption {
          type = types.nullOr types.int;
          default = null;
          example = 90;
          description = ''
            Events older than this many days are archived into
            archiveDirectory and then purged from the live database. Networks
            can override this with their activityRetentionDays. When unset
            (and no network overrides it), events are kept forever.
          '';
        };
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
      }]) cfg.networks ++ [{
        # Retention archives before it purges, so a retention without a place
        # to archive to would delete events without keeping them.
        assertion = !(cfg.activity.enable && cfg.activity.archiveDirectory
          == null && (cfg.activity.retentionDays != null
            || any (network: network.activityRetentionDays != null)
            cfg.networks));
        message =
          "services.fork-observer: activity.retentionDays (or a network's activityRetentionDays) is set, so activity.archiveDirectory must be set as well - old events are archived there before they are purged.";
      }];

    warnings = let
      optedIn = concatMap (network:
        map (node:
          "'${node.name}' (id ${toString node.id}) of network '${network.name}'")
        (filter (node: node.activityLog) network.nodes)) cfg.networks;
    in optional (!cfg.activity.enable && optedIn != [ ])
    "services.fork-observer: services.fork-observer.activity.enable is false, so no activity is recorded for the nodes that set activityLog = true: ${
      concatStringsSep ", " optedIn
    }.";

    users = {
      users.forkobserver = {
        isSystemUser = true;
        group = "forkobserver";
        home = "/var/lib/forkobserver";
      };
      groups.forkobserver = { };

    };

    systemd.tmpfiles.rules =
      [ "d '/var/lib/fork-observer/' 0770 'forkobserver' 'forkobserver' - -" ]
      ++ optional (cfg.activity.enable && cfg.activity.archiveDirectory != null)
      "d '${cfg.activity.archiveDirectory}' 0770 'forkobserver' 'forkobserver' - -";

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
        ${makeActivityConfig}
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
        ReadWriteDirectories = [ "/var/lib/fork-observer" ]
          ++ optional (cfg.activity.enable && cfg.activity.archiveDirectory
            != null) (toString cfg.activity.archiveDirectory);
        DynamicUser = true;
        User = "forkobserver";
        Group = "forkobserver";
      };
    };
  };
}
