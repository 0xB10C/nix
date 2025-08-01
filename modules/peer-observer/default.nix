{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. {}).peer-observer;
  cfg = config.services.peer-observer;
  hardening = import ../hardening.nix;
in {

  options = {

    services.peer-observer = {

      package = mkOption {
        type = types.package;
        default = pkg;
        defaultText = "pkgs.peer-observer";
        description = ''The peer-observer package to use.'';
      };

      natsAddress = mkOption {
        type = types.str;
        default = "127.0.0.1:4222";
        example = "127.0.0.1:4222";
        description = "Address of the NATS server the extractors and tools connect to.";
      };

      dependsOnNATSService = mkOption {
        type = types.str;
        default = "nats.service";
        example = null;
        description = "The nats.service the peer-observer extractors and tools depend on. Use any other service if NATS is not running locally.";
      };

      extractors = {

        ebpf = {
          enable = mkEnableOption "peer-observer ebpf-extractor";

          bitcoindPath = mkOption {
            type = types.str;
            default = null;
            description = "Path to the bitcoind executable.";
          };

          bitcoindPIDFile = mkOption {
            type = types.str;
            default = null;
            description = "The path to the bitcoind PID file. This file is read by systemd during extractor startup.";
          };

          dependsOn = mkOption {
            type = types.str;
            default = null;
            example = "bitcoind-mainnet";
            description = "The bitcoind-*.service peer-observer depends on. i.e. the bitcoind process which should be traced. This is always 'bitcoind-<name>', where <name> is the name of the NixOS bitcoind service.";
          };

          extraArgs= mkOption {
            type = types.str;
            default = "";
            example = "--no-connection-tracepoints --addrman-tracepoints";
            description = "Extra arguments to pass to the peer-observer extractor.";
          };
        };

        rpc = {
          enable = mkEnableOption "peer-observer rpc-extractor";

          rpcHost = mkOption {
            type = types.str;
            default = "127.0.0.1:8332";
            description = "Host of the RPC endpoint of Bitcoin Core";
          };

          rpcUser = mkOption {
            type = types.str;
            default = null;
            description = "RPC username";
          };

          rpcPass = mkOption {
            type = types.str;
            default = null;
            description = "RPC password";
          };

          dependsOn = mkOption {
            type = types.str;
            default = null;
            example = "bitcoind-mainnet";
            description = "The bitcoind-*.service peer-observer depends on. i.e. the bitcoind process which should be traced. This is always 'bitcoind-<name>', where <name> is the name of the NixOS bitcoind service.";
          };

          extraArgs= mkOption {
            type = types.str;
            default = "";
            example = "--query-interval 20";
            description = "Extra arguments to pass to the peer-observer RPC extractor.";
          };
        };

      };

      tools = {
        metrics = {
          enable = mkEnableOption "prometheus metrics";

          metricsAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8282";
            example = "127.0.0.1:8282";
            description = "Address the metrics webserver should listen on.";
          };
        };

        addrConnectivity = {
          enable = mkEnableOption "addr connectivity lookup";

          metricsAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8282";
            example = "127.0.0.1:8282";
            description = "Address the metrics webserver should listen on.";
          };
        };

        websocket = {
          enable = mkEnableOption "websocket tool";

          websocketAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8282";
            example = "127.0.0.1:8282";
            description = "Address the websocket server should listen on.";
          };
        };
      };

    };
  };
  config = mkIf (cfg.extractors.ebpf.enable || cfg.metrics.enable || cfg.addrConnectivity.enable || cfg.websocket.enable) {
    users = {
      users.peerobserver = { isSystemUser = true; group = "peerobserver"; };
      groups.peerobserver = { };
    };

    systemd.tmpfiles.rules = [
      "d '/var/lib/peer-observer/' 0770 'peerobserver' 'peerobserver' - -"
    ];

    # before we can start the peer-observer, wait until the PID file has been created by bitcoind
    # in the RuntimeDirectory
    systemd.services."${cfg.extractors.ebpf.dependsOn}".serviceConfig = {
      RuntimeDirectory = "${cfg.extractors.ebpf.dependsOn}";
      ExecStartPost = ''
        ${pkgs.bash}/bin/bash -c ' \
        while ! stat ${cfg.extractors.ebpf.bitcoindPIDFile} 2>/dev/null; do \
          echo \"Waiting for bitcoind PID file...\"; \
          sleep 1; \
        done; \
        chmod +r ${cfg.extractors.ebpf.bitcoindPIDFile}'
      '';
    };

    systemd.services.peer-observer-ebpf-extractor = mkIf cfg.extractors.ebpf.enable {
      description = "peer-observer ebpf-extractor";
      wantedBy = [ "multi-user.target" ];
      after = ["network-online.target" "${cfg.extractors.ebpf.dependsOn}.service" cfg.dependsOnNATSService ];
      wants = ["network-online.target" "${cfg.extractors.ebpf.dependsOn}.service" cfg.dependsOnNATSService ]; # 
      startLimitIntervalSec = 120;
      serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = "${cfg.package}/bin/ebpf-extractor --bitcoind-path ${cfg.extractors.ebpf.bitcoindPath} --bitcoind-pid-file ${cfg.extractors.ebpf.bitcoindPIDFile} --libbpf-debug --nats-address ${cfg.natsAddress} ${cfg.extractors.ebpf.extraArgs}";
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
          User = "peerobserver";
          Group = "peerobserver";
        };
      };

      systemd.services.peer-observer-rpc-extractor = mkIf cfg.extractors.rpc.enable {
        description = "peer-observer rpc-extractor";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" "${cfg.extractors.rpc.dependsOn}.service" cfg.dependsOnNATSService ];
        wants = ["network-online.target" "${cfg.extractors.rpc.dependsOn}.service" cfg.dependsOnNATSService ]; # 
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = "${cfg.package}/bin/rpc-extractor --rpc-host ${cfg.extractors.rpc.rpcHost} --rpc-user ${cfg.extractors.rpc.rpcUser} --rpc-password ${cfg.extractors.rpc.rpcPass} --nats-address ${cfg.natsAddress} ${cfg.extractors.rpc.extraArgs}";
          Restart = "always";
          # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;
          DynamicUser = true;
          User = "peerobserver";
          Group = "peerobserver";
        };
      };

      systemd.services.peer-observer-tool-metrics = mkIf cfg.tools.metrics.enable {
        description = "peer-observer metrics";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" cfg.dependsOnNATSService ];
        wants = ["network-online.target" cfg.dependsOnNATSService ];
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = "${cfg.package}/bin/metrics --nats-address ${cfg.natsAddress} --metrics-address ${cfg.tools.metrics.metricsAddress}";
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

      systemd.services.peer-observer-tool-addr-connectivity-check = mkIf cfg.tools.addrConnectivity.enable {
        description = "peer-observer addr-connectivity-check";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" cfg.dependsOnNATSService ];
        wants = ["network-online.target" cfg.dependsOnNATSService ];
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = "${cfg.package}/bin/connectivity-check --nats-address ${cfg.natsAddress} --metrics-address ${cfg.tools.addrConnectivity.metricsAddress}";
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

      systemd.services.peer-observer-tool-websocket = mkIf cfg.tools.websocket.enable {
        description = "peer-observer websocket";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" cfg.dependsOnNATSService ];
        wants = ["network-online.target" cfg.dependsOnNATSService ];
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = "${cfg.package}/bin/websocket --nats-address ${cfg.natsAddress} --websocket-address ${cfg.tools.websocket.websocketAddress}";
          Environment = "RUST_LOG=info";
          Restart = "always";
          # restart every 30 seconds. Limit this to 3 times in 'startLimitIntervalSec'
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;
          MemoryDenyWriteExecute = true;
          DynamicUser = true;
          User = "peerobserver";
          Group = "peerobserver";
        };
      };

  };
}
