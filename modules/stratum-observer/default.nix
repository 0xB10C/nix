{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).stratum-observer;
  cfg = config.services.stratum-observer;
  #hardening = import ../systemd-hardening.nix { };

  poolOptions = {
    options = {

      endpoint = mkOption {
        type = types.str;
        default = null;
        example = "stratum.example.com:3333";
        description = "Name of the pool.";
      };

      name = mkOption {
        type = types.str;
        default = null;
        example = "Example Pool";
        description = "Name of the pool. Must be unique.";
      };

      username = mkOption {
        type = types.str;
        default = null;
        example = "user.worker";
        description = "Username";
      };

      password = mkOption {
        type = types.str;
        default = "";
        example = "<empty>";
        description = "password";
      };

      maxLifetime = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = "295";
        description =
          "Optional maximal connection lifetime after we close and reconnect.";
      };
    };
  };

  nullOrStrToString = value: if value == null then "" else value;

  makePoolConfig = pool: ''
    { endpoint = "${pool.endpoint}", name = "${pool.name}", user = "${pool.username}", password = "${pool.password}" ${
      if pool.maxLifetime != null then
        ", max_lifetime=${toString pool.maxLifetime}"
      else
        ""
    } },
  '';

in {
  options = {

    services.stratum-observer = {
      enable = mkEnableOption "stratum-observer";

      package = mkOption {
        type = types.package;
        default = pkg;
        defaultText = "pkgs.stratum-observer";
        description = "The stratum-observer package to use.";
      };

      postgresqlUrl = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "postgres://<user>:<password>@<host>:<port>/<dbname>";
        description =
          "Connection URL to the PostgreSQL database. If null, no data will be recorded.";
      };

      websocketAddress = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "127.0.0.1:57127";
        description =
          "Address the websocker server listens on. If null, websocket will be disabled.";
      };

      pools = mkOption {
        type = types.listOf (types.submodule poolOptions);
        default = [ ];
        description = "Pools to connect to.";
      };

      logLevel = mkOption {
        type = types.enum [ "trace" "debug" "info" "warn" "error" ];
        default = "info";
        description = "The log level of stratum-observer.";
      };

    };
  };

  config = mkIf cfg.enable {
    users = {
      users.stratumobserver = {
        isSystemUser = true;
        group = "stratumobserver";
      };
      groups.stratumobserver = { };
    };

    systemd.services.stratum-observer = {
      description = "stratum-observer";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitIntervalSec = 120;
      preStart = ''
        cat <<EOF > /etc/stratum-observer/config.toml
        # stratum-observer configuration file

        ${lib.optionalString (cfg.postgresqlUrl != null) ''
          postgresql_url = "${nullOrStrToString cfg.postgresqlUrl}"
        ''}
        ${lib.optionalString (cfg.websocketAddress != null)
        ''websocket_address = "${nullOrStrToString cfg.websocketAddress}"''}
        pools = [
          ${concatMapStrings makePoolConfig cfg.pools}
        ]

        EOF'';

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/stratum-observer";
        Environment =
          "CONFIG_FILE=/etc/stratum-observer/config.toml RUST_LOG=${cfg.logLevel}";
        Restart = "always";
        # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
        RestartSec = 30;
        StartLimitBurst = 3;
        PermissionsStartOnly = true;
        MemoryDenyWriteExecute = true;
        ConfigurationDirectory = "stratum-observer"; # /etc/stratum-observer
        ConfigurationDirectoryMode = 710;
        DynamicUser = true;
        User = "stratumobserver";
        Group = "stratumobserver";
      };
    };
  };
}
