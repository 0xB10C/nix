{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).miningpool-observer;
  cfg = config.services.miningpool-observer;
  hardening = import ../hardening.nix;
in
{

  options = {

    services.miningpool-observer = {
      enable = mkEnableOption "miningpool-observer";

      # shared config

      package = mkOption {
        type = types.package;
        default = pkg;
        description = "The miningpool-observer package to use.";
      };

      databaseURL = mkOption {
        type = types.str;
        default = null;
        example = "postgres://<user>:<password>@<host>:<port>/<dbname>";
        description = "PostgreSQL connection URL";
      };

      # daemon only config

      bitcoindRPCPort = mkOption {
        type = types.port;
        default = 8332;
        description = "Bitcoin Core RPC server port";
      };

      bitcoindRPCHost = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bitcoin Core RPC server host";
      };

      bitcoindRPCUser = mkOption {
        type = types.str;
        default = null;
        description = "Bitcoin Core RPC server user";
      };

      bitcoindRPCPassword = mkOption {
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

      daemonLogLevel = mkOption {
        type = types.enum [
          "error"
          "warn"
          "info"
          "debug"
          "trace"
        ];
        default = "info";
        description = "Daemon Log Level";
      };

      retagTransactions = mkOption {
        type = types.bool;
        default = false;
        description = "Wether to re-tag transactions in the database on startup.";
      };

      daemonPrometheusAddress = mkOption {
        type = types.str;
        default = null;
        example = "127.0.0.1:9039";
        description = "Daemon Prometheus Address. If not set, then the Prometheus Metric Server is disabled.";
      };

      sanctionedAddressesUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://raw.githubusercontent.com/0xB10C/ofac-sanctioned-digital-currency-addresses/lists/sanctioned_addresses_XBT.txt";
        description = "URL where to query the OFAC sanctioned transactions from.";
      };

      # web only config

      address = mkOption {
        type = types.str;
        default = "127.0.0.1:8080";
        description = "Address the web-server listens on";
      };

      debugPages = mkOption {
        type = types.bool;
        default = false;
        description = "Allow access to the debug pages.";
      };

      siteTitle = mkOption {
        type = types.str;
        default = null;
        description = "Title shown on the site.";
      };

      siteFooter = mkOption {
        type = types.str;
        default = null;
        description = "Custom HTML footer.";
      };

      siteBaseURL = mkOption {
        type = types.str;
        default = null;
        description = "The URL of the site.";
      };

      webLogLevel = mkOption {
        type = types.enum [
          "error"
          "warn"
          "info"
          "debug"
          "trace"
        ];
        default = "info";
        description = "Web Log Level";
      };

    };
  };

  config = mkIf cfg.enable {
    users = {
      users.miningpoolobserver = {
        isSystemUser = true;
        group = "miningpoolobserver";
      };
      groups.miningpoolobserver = { };
    };

    systemd.services.miningpool-observer-daemon = {
      description = "miningpool-observer deamon";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitIntervalSec = 120;
      preStart = ''
        cat <<EOF > /etc/miningpool-observer/daemon-config.toml
                  # miningpool.observer deamon configuration file

                  database_url = "${cfg.databaseURL}"
                  log_level = "${cfg.daemonLogLevel}"

                  # rpc_cookie_file = "~/.bitcoin/.cookie"

                  rpc_host = "${cfg.bitcoindRPCHost}"
                  rpc_port = ${toString cfg.bitcoindRPCPort}
                  rpc_user = "${cfg.bitcoindRPCUser}"
                  rpc_password = "${cfg.bitcoindRPCPassword}"

                  retag_transactions = ${boolToString cfg.retagTransactions}

                  ${
                    optionalString (
                      cfg.sanctionedAddressesUrl != null
                    ) ''sanctioned_addresses_url = "${cfg.sanctionedAddressesUrl}"''
                  }

                  
                  [prometheus]
                    enable = ${boolToString (cfg.daemonPrometheusAddress != null)}
                    address = "${cfg.daemonPrometheusAddress}"

        EOF'';

      serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
        ExecStart = "${cfg.package}/bin/miningpool-observer-daemon";
        Environment = "CONFIG_FILE=/etc/miningpool-observer/daemon-config.toml";
        Restart = "always";
        # restart every 30 seconds. Limit this to 3 times in 'startLimitIntervalSec'
        RestartSec = 30;
        StartLimitBurst = 3;
        PermissionsStartOnly = true;
        MemoryDenyWriteExecute = true;
        ConfigurationDirectory = "miningpool-observer"; # /etc/miningpool-observer
        ConfigurationDirectoryMode = 710;
        DynamicUser = true;
        User = "miningpoolobserver";
        Group = "miningpoolobserver";
      };
    };

    systemd.services.miningpool-observer-web = {
      description = "miningpool-observer web";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitIntervalSec = 120;
      preStart = ''
        cat <<EOF > /etc/miningpool-observer/web-config.toml
                  # miningpool.observer web configuration file

                  database_url = "${cfg.databaseURL}"
                  log_level = "${cfg.webLogLevel}"
                  address = "${cfg.address}"
                  debug_pages = ${boolToString cfg.debugPages}
                  www_dir_path = "${cfg.package}/www"

                  [site]
                      title = "${cfg.siteTitle}"
                      footer = """
                        ${cfg.siteFooter}
                      """
                      base_url =  "${cfg.siteBaseURL}"
        EOF'';

      serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
        ExecStart = "${cfg.package}/bin/miningpool-observer-web";
        Environment = "CONFIG_FILE=/etc/miningpool-observer/web-config.toml";
        Restart = "always";
        # restart every 30 seconds. Limit this to 3 times in 'startLimitIntervalSec'
        RestartSec = 30;
        StartLimitBurst = 3;
        PermissionsStartOnly = true;
        MemoryDenyWriteExecute = true;
        ConfigurationDirectory = "miningpool-observer"; # /etc/miningpool-observer
        ConfigurationDirectoryMode = 710;
        DynamicUser = true;
        User = "miningpoolobserver";
        Group = "miningpoolobserver";
      };
    };
  };
}
