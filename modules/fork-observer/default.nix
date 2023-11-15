{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).fork-observer;
  cfg = config.services.fork-observer;
  #hardening = import ../systemd-hardening.nix { };

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

      description = mkOption {
        type = types.str;
        default = "";
        description = "Description of the network.";
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

    };
  };

  makeNetworkConfig = network: ''
    [[networks]]
    id = ${toString network.id}
    name = "${network.name}"
    description = "${network.description}"
    min_fork_height = ${toString network.minForkHeight}
    max_interesting_heights = ${toString network.maxInterestingHeights}

    ${concatMapStrings makeNodeConfig network.nodes}
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
        type = types.str;
        default = null;
        description = "Bitcoin Core RPC server user";
      };

      rpcPassword = mkOption {
        type = types.str;
        default = null;
        description = "Bitcoin Core RPC server password";
      };

      bitcoindRPCCookieFile = mkOption {
        type = types.path;
        default = null;
        example = "~/.bitcoin/.cookie";
        description = "Bitcoin Core RPC cookie file";
      };

      useREST = mkOption {
        type = types.bool;
        default = true;
        description =
          "If the Bitcoin Core REST interface should be used (otherwise slower RPC will be used).";
      };

      implementation = mkOption {
        type = types.enum [ "BitcoinCore" "btcd" ];
        default = "BitcoinCore";
        description = "The Bitcoin implementation to query";
      };

    };
  };

  makeNodeConfig = node: ''

    [[networks.nodes]]
    id = ${toString node.id}
    name = "${node.name}"
    description = "${node.description}"
    # TODO: rpc_cookie_file = "~/.bitcoin/.cookie"
    rpc_host = "${node.rpcHost}"
    rpc_port = ${toString node.rpcPort}
    rpc_user = "${node.rpcUser}"
    rpc_password = "${node.rpcPassword}"
    use_rest = ${boolToString node.useREST}
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
        description = "Name of the sled database folder.";
      };

      queryInterval = mkOption {
        type = types.int;
        default = 10;
        description = "Second interval in which to query getchaintips.";
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

      serviceConfig = {
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
