{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. {}).peer-observer;
  cfg = config.services.peer-observer;
  hardening = import ../hardening.nix;

  natsOptions = {
    options = {
      address = mkOption {
        type = types.str;
        default = "127.0.0.1:4222";
        example = "nats.example.com:4333";
        description = "The NATS server address the extractors and tools connect to.";
      };

      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "satoshi";
        description = "The username needed to connect to the NATS server.";
      };

      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "passw0rd";
        description = "The password needed to connect to the NATS server.";
      };

      passwordFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/nats-password";
        description = "The password needed to connect to the NATS server.";
      };
    };

  };

  natsOpt = mkOption {
    default = { };
    type = types.submodule natsOptions;
    description = "Configuration for the connection to the NATS server.";
  };

in {

  options = {

    services.peer-observer = {

      package = mkOption {
        type = types.package;
        default = pkg;
        defaultText = "pkgs.peer-observer";
        description = ''The peer-observer package to use.'';
      };

      dependsOnNATSService = mkOption {
        type = types.str;
        default = "nats.service";
        example = null;
        description = "The nats.service the peer-observer extractors and tools depend on. Use any other service if NATS is not running locally.";
      };

      extractors = {
        dependOn = mkOption {
          type = types.str;
          default = null;
          example = "bitcoind-mainnet";
          description = "The bitcoind-*.service peer-observer extractors depend on. i.e. the bitcoind process which should be monitored. This is always 'bitcoind-<name>', where <name> is the name of the NixOS bitcoind service.";
        };

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

          nats = natsOpt;

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

          nats = natsOpt;

          extraArgs= mkOption {
            type = types.str;
            default = "";
            example = "--query-interval 20";
            description = "Extra arguments to pass to the peer-observer RPC extractor.";
          };
        };

        p2p = {
          enable = mkEnableOption "peer-observer p2p-extractor";

          network = mkOption {
            type = types.enum ["mainnet" "testnet3" "testnet4" "signet" "regtest"];
            default = "mainnet";
            description = "Network the Bitcoin node";
          };

          p2pAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8444";
            description = "Address the p2p-extractor listens on for connections from the Bitcoin node. Run the Bitcoin node with `--addnode=ip:port` to connect it to this address.";
          };

          nats = natsOpt;

          extraArgs= mkOption {
            type = types.str;
            default = "";
            example = "--ping-interval 20";
            description = "Extra arguments to pass to the peer-observer p2p-extractor.";
          };
        };

        log = {
          enable = mkEnableOption "peer-observer log-extractor";

          debugLog = mkOption {
            type = types.str;
            default = null;
            description = "Path to the bitcoind debug.log file";
          };

          nats = natsOpt;

          extraArgs= mkOption {
            type = types.str;
            default = "";
            example = "";
            description = "Extra arguments to pass to the peer-observer log-extractor.";
          };

        };

      };

      tools = {
        metrics = {
          enable = mkEnableOption "prometheus metrics";

          nats = natsOpt;

          metricsAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8282";
            example = "127.0.0.1:8282";
            description = "Address the metrics webserver should listen on.";
          };
        };

        addrConnectivity = {
          enable = mkEnableOption "addr connectivity lookup";

          nats = natsOpt;

          metricsAddress = mkOption {
            type = types.str;
            default = "127.0.0.1:8282";
            example = "127.0.0.1:8282";
            description = "Address the metrics webserver should listen on.";
          };
        };

        websocket = {
          enable = mkEnableOption "websocket tool";

          nats = natsOpt;

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
  config = mkIf (cfg.extractors.ebpf.enable || cfg.extractors.rpc.enable || cfg.extractors.p2p.enable || cfg.tools.metrics.enable || cfg.tools.addrConnectivity.enable || cfg.tools.websocket.enable) {
    users = {
      users.peerobserver = { isSystemUser = true; group = "peerobserver"; };
      groups.peerobserver = { };
    };

    systemd.tmpfiles.rules = [
      "d '/var/lib/peer-observer/' 0770 'peerobserver' 'peerobserver' - -"
    ];

    # before we can start the peer-observer, wait until the PID file has been created by bitcoind
    # in the RuntimeDirectory
    systemd.services."${cfg.extractors.dependOn}".serviceConfig = {
      RuntimeDirectory = "${cfg.extractors.dependOn}";
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
      after = ["network-online.target" "${cfg.extractors.dependOn}.service" cfg.dependsOnNATSService ];
      wants = ["network-online.target" "${cfg.extractors.dependOn}.service" cfg.dependsOnNATSService ]; #
      startLimitIntervalSec = 120;
      serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = ''
            ${cfg.package}/bin/ebpf-extractor \
            --bitcoind-path ${cfg.extractors.ebpf.bitcoindPath} \
            --bitcoind-pid-file ${cfg.extractors.ebpf.bitcoindPIDFile} \
            --libbpf-debug \
            --nats-address ${cfg.extractors.ebpf.nats.address} \
            ${optionalString (cfg.extractors.ebpf.nats.username != null) "--nats-username ${cfg.extractors.ebpf.nats.username}" } \
            ${optionalString (cfg.extractors.ebpf.nats.password != null) "--nats-password ${cfg.extractors.ebpf.nats.password}" } \
            ${optionalString (cfg.extractors.ebpf.nats.passwordFile != null) "--nats-password-file ${cfg.extractors.ebpf.nats.passwordFile}" } \
            ${cfg.extractors.ebpf.extraArgs}'';
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
        after = ["network-online.target" "${cfg.extractors.dependOn}.service" cfg.dependsOnNATSService ];
        wants = ["network-online.target" "${cfg.extractors.dependOn}.service" cfg.dependsOnNATSService ]; #
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = ''
            ${cfg.package}/bin/rpc-extractor \
            --rpc-host ${cfg.extractors.rpc.rpcHost} \
            --rpc-user ${cfg.extractors.rpc.rpcUser} \
            --rpc-password ${cfg.extractors.rpc.rpcPass} \
            --nats-address ${cfg.extractors.rpc.nats.address} \
            ${optionalString (cfg.extractors.rpc.nats.username != null) "--nats-username ${cfg.extractors.rpc.nats.username}" } \
            ${optionalString (cfg.extractors.rpc.nats.password != null) "--nats-password ${cfg.extractors.rpc.nats.password}" } \
            ${optionalString (cfg.extractors.rpc.nats.passwordFile != null) "--nats-password-file ${cfg.extractors.rpc.nats.passwordFile}" } \
            ${cfg.extractors.rpc.extraArgs}
          '';
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

      systemd.services.peer-observer-p2p-extractor = mkIf cfg.extractors.p2p.enable {
        description = "peer-observer p2p-extractor";
        wantedBy = [ "multi-user.target" ];
        # we don't depend on a Bitcoin service here. Ideally, we want the p2p-extractor to start before
        # a bitcoind starts for the bitcoind to connect to the p2p-extractor right away. We don't enforce
        # this as bitcoind will try to reconnect every minute.
        after = ["network-online.target" cfg.dependsOnNATSService ];
        wants = ["network-online.target" cfg.dependsOnNATSService ];
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = ''
            ${cfg.package}/bin/p2p-extractor \
            --p2p-network ${cfg.extractors.p2p.network} \
            --p2p-address ${cfg.extractors.p2p.p2pAddress} \
            --nats-address ${cfg.extractors.p2p.nats.address} \
            ${optionalString (cfg.extractors.p2p.nats.username != null) "--nats-username ${cfg.extractors.p2p.nats.username}" } \
            ${optionalString (cfg.extractors.p2p.nats.password != null) "--nats-password ${cfg.extractors.p2p.nats.password}" } \
            ${optionalString (cfg.extractors.p2p.nats.passwordFile != null) "--nats-password-file ${cfg.extractors.p2p.nats.passwordFile}" } \
            ${cfg.extractors.p2p.extraArgs}'';
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

      systemd.services.peer-observer-log-extractor-fifo-pipe = mkIf cfg.extractors.log.enable {
        description = "peer-observer log-extractor fifo pipe";
        wantedBy = [ "multi-user.target" ];
        after = ["network-online.target" "${cfg.extractors.dependOn}.service" ];
        wants = ["network-online.target" "${cfg.extractors.dependOn}.service" ];
        startLimitIntervalSec = 120;
        serviceConfig = builtins.removeAttrs (hardening.default // hardening.allowAllIPAddresses // {
          ExecStartPre = [
            "${pkgs.coreutils}/bin/rm -f /var/lib/peer-observer/log-extractor-debug-log.pipe"
            "${pkgs.coreutils}/bin/mkfifo /var/lib/peer-observer/log-extractor-debug-log.pipe"
            "${pkgs.coreutils}/bin/chown peerobserver:peerobserver /var/lib/peer-observer/log-extractor-debug-log.pipe"
          ];
          ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/tail -f ${cfg.extractors.log.debugLog} > /var/lib/peer-observer/log-extractor-debug-log.pipe'";
          Restart = "always";
          # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;

          # Override: otherwise, we can't read the debug.log file since it's owned by the 'nobody' user/group
          PrivateUsers = false;
          ProtectSystem = "full";
          # give it the default CapabilityBoundingSet (hardening.default sets it to "", which isn't enough)
        }) ["CapabilityBoundingSet"];
      };

      systemd.services.peer-observer-log-extractor = mkIf cfg.extractors.log.enable {
        description = "peer-observer log-extractor";
        wantedBy = [ "multi-user.target" ];
        # we don't depend on a Bitcoin service here, but we depend on a pipe file being present.
        after = ["network-online.target" cfg.dependsOnNATSService "peer-observer-log-extractor-fifo-pipe.service"];
        wants = ["network-online.target" cfg.dependsOnNATSService "peer-observer-log-extractor-fifo-pipe.service"];
        startLimitIntervalSec = 120;
        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          ExecStart = ''
            ${cfg.package}/bin/log-extractor \
            --bitcoind-pipe /var/lib/peer-observer/log-extractor-debug-log.pipe \
            --nats-address ${cfg.extractors.log.nats.address} \
            ${optionalString (cfg.extractors.log.nats.username != null) "--nats-username ${cfg.extractors.log.nats.username}" } \
            ${optionalString (cfg.extractors.log.nats.password != null) "--nats-password ${cfg.extractors.log.nats.password}" } \
            ${optionalString (cfg.extractors.log.nats.passwordFile != null) "--nats-password-file ${cfg.extractors.log.nats.passwordFile}" } \
            ${cfg.extractors.log.extraArgs}
          '';
          Restart = "always";
          # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
          RestartSec = 30;
          StartLimitBurst = 3;
          PermissionsStartOnly = true;
          DynamicUser = true;
          WorkingDirectory = "/var/lib/peer-observer";
          ReadOnlyPaths = "/var/lib/peer-observer";
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
          ExecStart = ''
            ${cfg.package}/bin/metrics \
            --nats-address ${cfg.tools.metrics.nats.address} \
            --metrics-address ${cfg.tools.metrics.metricsAddress} \
            ${optionalString (cfg.tools.metrics.nats.username != null) "--nats-username ${cfg.tools.metrics.nats.username}" } \
            ${optionalString (cfg.tools.metrics.nats.password != null) "--nats-password ${cfg.tools.metrics.nats.password}" } \
            ${optionalString (cfg.tools.metrics.nats.passwordFile != null) "--nats-password-file ${cfg.tools.metrics.nats.passwordFile}" }
          '';
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
          ExecStart = ''
            ${cfg.package}/bin/connectivity-check \
            --metrics-address ${cfg.tools.addrConnectivity.metricsAddress} \
            --nats-address ${cfg.tools.addrConnectivity.nats.address} \
            ${optionalString (cfg.tools.addrConnectivity.nats.username != null) "--nats-username ${cfg.tools.addrConnectivity.nats.username}" } \
            ${optionalString (cfg.tools.addrConnectivity.nats.password != null) "--nats-password ${cfg.tools.addrConnectivity.nats.password}" } \
            ${optionalString (cfg.tools.addrConnectivity.nats.passwordFile != null) "--nats-password-file ${cfg.tools.addrConnectivity.nats.passwordFile}" }
          '';
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
          ExecStart = ''
            ${cfg.package}/bin/websocket \
            --websocket-address ${cfg.tools.websocket.websocketAddress} \
            --nats-address ${cfg.tools.websocket.nats.address} \
            ${optionalString (cfg.tools.websocket.nats.username != null) "--nats-username ${cfg.tools.websocket.nats.username}" } \
            ${optionalString (cfg.tools.websocket.nats.password != null) "--nats-password ${cfg.tools.websocket.nats.password}" } \
            ${optionalString (cfg.tools.websocket.nats.passwordFile != null) "--nats-password-file ${cfg.tools.websocket.nats.passwordFile}" }
          '';
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
