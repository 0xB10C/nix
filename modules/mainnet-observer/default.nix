{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).mainnet-observer-backend;
  cfg = config.services.mainnet-observer-backend;
  hardening = import ../hardening.nix;
in
{
  options = {

    services.mainnet-observer-backend = {
      enable = mkEnableOption "mainnet-observer backend";

      package = mkOption {
        type = types.package;
        default = pkg;
        description = "The mainnet-observer backend package to use.";
      };

      port = mkOption {
        type = types.port;
        default = 8332;
        description = "Bitcoin Core REST server port";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "Bitcoin Core REST server host";
      };

      databasePath = mkOption {
        type = types.str;
        default = "/var/lib/mainnet-observer/db.sqlite";
        description = "Bitcoin Core RPC server host";
      };

      csvPath = mkOption {
        type = types.str;
        default = "/var/lib/mainnet-observer/csv";
        description = "Directory where the CSV files are generated to.";
      };

      timerOnCalendar = mkOption {
        type = types.str;
        default = "01:32";
        description = "Systemd OnCalendar run-interval of the mainnet-observer backend.";
      };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.mainnet-observer = {
        isSystemUser = true;
        group = "mainnet-observer";
        home = "/var/lib/mainnet-observer";
      };
      groups.mainnet-observer = { };
    };

    systemd.tmpfiles.rules = [
      "d '/var/lib/mainnet-observer' 0775 'mainnet-observer' 'mainnet-observer' - -"
    ];

    systemd.timers."mainnet-observer-backend" = {
      wantedBy = [ "timers.target" ];
      partOf = [ "mainnet-observer-backend.service" ];
      timerConfig.OnCalendar = cfg.timerOnCalendar;
    };

    systemd.services.mainnet-observer-backend = {
      description = "mainnet-observer backend";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      script = ''
        mkdir -p ${cfg.csvPath}
        chmod a+r ${cfg.csvPath}
        ${cfg.package}/bin/mainnet-observer-backend \
          --rest-host ${cfg.host} \
          --rest-port ${toString cfg.port} \
          --database-path ${cfg.databasePath} \
          --csv-path ${cfg.csvPath}
      '';
      serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
        Type = "oneshot";
        User = "mainnet-observer";
        Group = "mainnet-observer";
        ReadWriteDirectories = "/var/lib/mainnet-observer";
      };
    };
  };
}
