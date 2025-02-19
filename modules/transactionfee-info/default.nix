{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).transactionfee-info-backend;
  cfg = config.services.transactionfee-info-backend;
  hardening = import ../hardening.nix;
in
{
  options = {

    services.transactionfee-info-backend = {
      enable = mkEnableOption "transactionfee-info backend";

      package = mkOption {
        type = types.package;
        default = pkg;
        description = "The transactionfee-info backend package to use.";
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
        default = "/var/lib/transactionfee-info/db.sqlite";
        description = "Bitcoin Core RPC server host";
      };

      csvPath = mkOption {
        type = types.str;
        default = "/var/lib/transactionfee-info/csv";
        description = "Directory where the CSV files are generated to.";
      };

      timerOnCalendar = mkOption {
        type = types.str;
        default = "01:32";
        description = "Systemd OnCalendar run-interval of the transactionfee-info backend.";
      };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users.transactionfeeinfo = {
        isSystemUser = true;
        group = "transactionfeeinfo";
        home = "/var/lib/transactionfee-info";
      };
      groups.transactionfeeinfo = { };
    };

    systemd.tmpfiles.rules = [
      "d '/var/lib/transactionfee-info' 0775 'transactionfeeinfo' 'transactionfeeinfo' - -"
    ];

    systemd.timers."transactionfee-info-backend" = {
      wantedBy = [ "timers.target" ];
      partOf = [ "transactionfee-info-backend.service" ];
      timerConfig.OnCalendar = cfg.timerOnCalendar;
    };

    systemd.services.transactionfee-info-backend = {
      description = "transactionfee-info backend";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      script = ''
        mkdir -p ${cfg.csvPath}
        chmod a+r ${cfg.csvPath}
        ${cfg.package}/bin/transactionfee-info-backend \
          --rest-host ${cfg.host} \
          --rest-port ${toString cfg.port} \
          --database-path ${cfg.databasePath} \
          --csv-path ${cfg.csvPath}
      '';
      serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
        Type = "oneshot";
        User = "transactionfeeinfo";
        Group = "transactionfeeinfo";
        ReadWriteDirectories = "/var/lib/transactionfee-info";
      };
    };
  };
}
