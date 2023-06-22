{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. {}).peer-observer;
  cfg = config.services.peer-observer;
  hardening = {};#import ../systemd-hardening.nix { };
in {

  options = {

    services.peer-observer = {
      enable = mkEnableOption "peer-observer";

      package = mkOption {
        type = types.package;
        default = pkg;
        defaultText = "pkgs.peer-observer";
        description = ''The peer-observer package to use.'';
      };

      metrics_address = mkOption {
        type = types.str;
        default = "127.0.0.1:8282";
        example = "127.0.0.1:8282";
        description = "Address the metrics webserver should listen on.";
      };

      bitcoind_path = mkOption {
        type = types.str;
        default = null;
        description = "Path to the bitcoind executable.";
      };

      addrConnectivityLookup = {
        enable = mkEnableOption "addr connectivity lookup";

        metrics_address = {
          host = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "Host the addrConnectivtyLookup metrics webserver should listen on.";
          };

          port = mkOption {
            type = types.port;
            default = 32847;
            description = "Port the addrConnectivtyLookup metrics webserver should listen on.";
          };
        };
      };
    };
  };
  config = mkIf cfg.enable {
    users = {
      users.peerobserver = { isSystemUser = true; group = "peerobserver"; };
      groups.peerobserver = { };
    };

    systemd.tmpfiles.rules = [
      "d '/var/lib/peer-observer/' 0770 'peerobserver' 'peerobserver' - -"
    ];

    systemd.services.peer-observer-extractor = {
      description = "peer observer";
      wantedBy = [ "multi-user.target" ];
      after = ["network-online.target" ];
      wants = ["network-online.target" ];
      startLimitIntervalSec = 120;
      serviceConfig =
        {
          ExecStart = "${cfg.package}/bin/extractor ${cfg.bitcoind_path}";
          Restart = "always";
          # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;
          DynamicUser = true;
          ProtectProc = "default";
          ProcSubset = "all";
          AmbientCapabilities="CAP_BPF CAP_PERFMON CAP_SYS_RESOURCE";
          CapabilityBoundingSet="CAP_BPF CAP_PERFMON CAP_SYS_RESOURCE";
          PrivateUsers = "false";
          SystemCallFilter = [
            "@system-service"
            "~add_key clone3 get_mempolicy kcmp keyctl mbind move_pages name_to_handle_at personality process_vm_readv process_vm_writev request_key set_mempolicy setns unshare userfaultfd"
            "bpf"
            "clone3"
            "@debug"
          ];
          User = "root";
          Group = "root";
        };
      };

      systemd.services.peer-observer-metrics = {
        description = "peer-observer metrics";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" "peer-observer-processor.service" ];
        wants = ["network-online.target" "peer-observer-processor.service" ];
        startLimitIntervalSec = 120;
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/metrics ${cfg.metrics_address}";
          Environment = "RUST_LOG=info";
          Restart = "always";
          # restart every 30 seconds. Limit this to 3 times in 'startLimitIntervalSec'
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;
          MemoryDenyWriteExecute = true;
          ConfigurationDirectory = "peer-observer";
          ConfigurationDirectoryMode = 710;
          DynamicUser = true;
          User = "peerobserver";
          Group = "peerobserver";
        };
      };

      systemd.services.peer-observer-addr-connectivity-check = mkIf cfg.addrConnectivityLookup.enable {
        description = "peer-observer addr-connectivity-check";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" "peer-observer-processor.service" ];
        wants = ["network-online.target" "peer-observer-processor.service" ];
        startLimitIntervalSec = 120;
        serviceConfig = {
          ExecStart = "${cfg.package}/bin/connectivity-check ${cfg.addrConnectivityLookup.metrics_address.host}:${toString cfg.addrConnectivityLookup.metrics_address.port}";
          Environment = "RUST_LOG=info";
          Restart = "always";
          # restart every 30 seconds. Limit this to 3 times in 'startLimitIntervalSec'
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;
          MemoryDenyWriteExecute = true;
          ConfigurationDirectory = "peer-observer";
          WorkingDirectory = "/var/lib/peer-observer";
          ReadWriteDirectories = "/var/lib/peer-observer";
          ConfigurationDirectoryMode = 710;
          DynamicUser = true;
          User = "peerobserver";
          Group = "peerobserver";
        };
      };

  };
}
