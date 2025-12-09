{ pkgs, ... }:

let

  PEER_OBSERVER_METRICS_PORT = 10090;
  PEER_OBSERVER_ADDR_CHECK_METRICS_PORT = 10080;
  PEER_OBSERVER_WEBSOCKET_PORT = 10060;
  PEER_OBSERVER_P2PEXPORTER_PORT = 10070;
  NATS_PORT = 4222;
  BITCOIND_PORT = 12345;
  BITCOIND2_PORT = 23456;
  BITCOIND_RPC_PORT = 8332;

in {
  name = "peer-observer";

  nodes.machine = { config, lib, ... }: {
    imports = [
      ../modules/peer-observer/default.nix
    ];

    virtualisation.cores = 1;
    # extra memory needed for peer-observer extractor huge-msg table
    virtualisation.memorySize = 3072;

    services.bitcoind."regtest" = {
      enable = true;
      package = (pkgs.callPackage ./.. { }).bitcoind-tracing-v29;
      port = BITCOIND_PORT;
      # needs to be "/run/bitcoind-<name>/bitcoind.pid"
      pidFile = "/run/bitcoind-regtest/bitcoind.pid";
      extraConfig = ''
        regtest=1
        debug=net


        [regtest]
        # used to test the rpc-extractor via getpeerinfo (this will show up as a peer)
        addnode=127.0.0.1:${toString BITCOIND2_PORT}
        # used to test the p2p-extractor
        addnode=127.0.0.1:${toString PEER_OBSERVER_P2PEXPORTER_PORT}
      '';
      rpc = {
        port = BITCOIND_RPC_PORT;
        users.peer-observer = {
          name = "peer-observer";
          passwordHMAC =
            "a086e1c71a326b56b490249203406ad6$30d91b328c812f1faf82783df5388b808b3a91a945a0f8bae071c2bef4549e7e";
        };
      };
    };
    # start the p2p-extractor before we start bitcoind:
    # bitcoind will then directly connect to the p2p-extractor and not after a minute
    # this ensures a faster test
    systemd.services.bitcoind-regtest.serviceConfig = {
      after = [ "peer-observer-p2p-extractor.service" ];
      wants = [ "peer-observer-p2p-extractor.service" ];
    };

    services.bitcoind."regtest2" = {
      enable = true;
      package = (pkgs.callPackage ./.. { }).bitcoind-tracing-v29;
      port = BITCOIND2_PORT;
      extraConfig = ''
        regtest=1
        debug=net

        [regtest]
        # used to test the rpc-extractor via getpeerinfo (this node will show up as a connection)
        addnode=127.0.0.1:${toString BITCOIND_PORT}
      '';
    };

    services.nats = {
      enable = true;
      settings = {
        listen = "127.0.0.1:${toString NATS_PORT}";
      };
    };

    # In a test, we want to never restart the extractor if it fails as this could mean
    # there is something wrong.
    systemd.services.peer-observer-extractor.serviceConfig.Restart = lib.mkForce "no";
    systemd.services.peer-observer-extractor.serviceConfig.Environment = "RUST_LOG=debug";
    services.peer-observer = {

      natsAddress = "127.0.0.1:${toString NATS_PORT}";
      dependsOnNATSService = "nats.service";

      extractors = {
        dependOn = "bitcoind-regtest"; # services.bitcoind.regtest above will create the bitcoind-regtest.service

        ebpf = {
          enable = true;
          bitcoindPath = "${config.services.bitcoind.regtest.package}/bin/bitcoind";
          bitcoindPIDFile = config.services.bitcoind.regtest.pidFile;
        };

        rpc = {
          enable = true;
          rpcHost = "127.0.0.1:${toString BITCOIND_RPC_PORT}";
          rpcUser = "peer-observer";
          rpcPass = "hunter2";
        };

        p2p = {
          enable = true;
          p2pAddress = "127.0.0.1:${toString PEER_OBSERVER_P2PEXPORTER_PORT}";
          network = "regtest";
          extraArgs = "--ping-interval 2 --log-level TRACE";
        };

        log = {
          enable = true;
          debugLog = "/var/lib/bitcoind-regtest/regtest/debug.log";
        };
      };

      tools = {
        metrics = {
          enable = true;
          metricsAddress = "127.0.0.1:${toString PEER_OBSERVER_METRICS_PORT}";
        };

        addrConnectivity = {
          enable = true;
          metricsAddress = "127.0.0.1:${toString PEER_OBSERVER_ADDR_CHECK_METRICS_PORT}";
        };

        websocket = {
          enable = true;
          websocketAddress = "127.0.0.1:${toString PEER_OBSERVER_WEBSOCKET_PORT}";
        };
      };
    };
  };

  testScript = ''
    import time

    machine.wait_for_unit("nats.service", timeout=15)
    machine.wait_for_open_port(${toString NATS_PORT})

    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_PORT})
    machine.wait_for_open_port(${toString BITCOIND2_PORT})
    machine.wait_for_open_port(${toString BITCOIND_RPC_PORT})

    machine.wait_for_unit("peer-observer-ebpf-extractor.service", timeout=15)
    machine.wait_for_unit("peer-observer-rpc-extractor.service", timeout=15)
    machine.wait_for_unit("peer-observer-p2p-extractor.service", timeout=15)
    machine.wait_for_open_port(${toString PEER_OBSERVER_P2PEXPORTER_PORT})
    machine.wait_for_unit("peer-observer-log-extractor-fifo-pipe.service", timeout=15)
    machine.wait_for_unit("peer-observer-log-extractor.service", timeout=15)

    # give the extractor a bit of time to start up
    time.sleep(5)

    machine.systemctl("start peer-observer-tool-metrics.service")
    machine.wait_for_unit("peer-observer-tool-metrics.service", timeout=15)
    machine.wait_for_open_port(${toString PEER_OBSERVER_METRICS_PORT})
    metrics = machine.succeed("curl http://127.0.0.1:${toString PEER_OBSERVER_METRICS_PORT}/metrics")
    print(metrics)
    print("to test the metrics-tool, check that the peerobserver_runtime_start_timestamp metric is in there and that the value isn't zero:")
    assert "peerobserver_runtime_start_timestamp" in metrics
    assert "peerobserver_runtime_start_timestamp 0" not in metrics
    print("OK!")

    print("to test the rpc-extractor, check if the peerobserver_rpc_peer_info_num_peers metric is in there and that the value isn't zero:")
    assert "peerobserver_rpc_peer_info_num_peers" in metrics
    assert "peerobserver_rpc_peer_info_num_peers 0" not in metrics
    print("OK!")

    print("to test the p2p-extractor, check if the peerobserver_p2pextractor_ping_duration_nanoseconds metric is in there and that the value isn't zero:")
    assert "peerobserver_p2pextractor_ping_duration_nanoseconds" in metrics
    assert "peerobserver_p2pextractor_ping_duration_nanoseconds 0" not in metrics
    print("OK!")

    print("to test the log-extractor, check if the peerobserver_log_events metric is in there and that the value isn't zero:")
    assert "peerobserver_log_events" in metrics
    assert "peerobserver_log_events 0" not in metrics
    print("OK!")

    machine.systemctl("start peer-observer-tool-addr-connectivity-check.service")
    machine.wait_for_unit("peer-observer-tool-addr-connectivity-check.service", timeout=15)
    machine.wait_for_open_port(${toString PEER_OBSERVER_ADDR_CHECK_METRICS_PORT})

    # right after start up, the addr connectivity check metrics endpoint
    # returns an empty response as no metrics have been set
    metrics2 = machine.succeed("curl http://127.0.0.1:${toString PEER_OBSERVER_ADDR_CHECK_METRICS_PORT}/metrics")
    assert len(metrics2) == 0

    machine.systemctl("start peer-observer-tool-websocket.service")
    machine.wait_for_unit("peer-observer-tool-websocket.service", timeout=15)
    # this will "panic" with Failed to accept WebSocket: HandshakeError::Failure(Protocol(HandshakeIncomplete))
    # but that's expected as we only open a TCP connection to the websocket server, and don't actually do the Websocket
    # handshake
    machine.wait_for_open_port(${toString PEER_OBSERVER_WEBSOCKET_PORT})

    # wait for the ebpf-extractor again, since it might fail when attaching the a tracepoint
    time.sleep(5)
    print("Checking if the ebpf extractor has crashed while trying to attach to a tracepoint..")
    machine.wait_for_unit("peer-observer-ebpf-extractor.service", timeout=2)
  '';
}
