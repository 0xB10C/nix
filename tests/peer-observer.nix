{ pkgs, ... }:

let

  PEER_OBSERVER_METRICS_PORT = 10090;
  PEER_OBSERVER_ADDR_CHECK_METRICS_PORT = 10080;
  PEER_OBSERVER_WEBSOCKET_PORT = 10060;
  NATS_PORT = 4222;
  BITCOIND_PORT = 12345;

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
      port = 12345;
      # needs to be "/run/bitcoind-<name>/bitcoind.pid"
      pidFile = "/run/bitcoind-regtest/bitcoind.pid";
      extraConfig = ''
        regtest=1
        debug=net
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
        ebpf = {
          enable = true;
          dependsOn = "bitcoind-regtest"; # services.bitcoind.regtest above will create the bitcoind-regtest.service 
          bitcoindPath = "${config.services.bitcoind.regtest.package}/bin/bitcoind";
          bitcoindPIDFile = config.services.bitcoind.regtest.pidFile;
        };
      };

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

  testScript = ''
    import time
  
    # HACK: don't start these from the beginning
    # needs https://github.com/0xB10C/peer-observer/issues/37
    machine.systemctl("stop peer-observer-metrics.service")
    machine.systemctl("stop peer-observer-websocket.service")
    machine.systemctl("stop peer-observer-addr-connectivity-check.service")
  
    machine.wait_for_unit("nats.service", timeout=15)
    machine.wait_for_open_port(${toString NATS_PORT})

    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_PORT})
    
    machine.wait_for_unit("peer-observer-ebpf-extractor.service", timeout=15)

    # give the extractor a bit of time to start up
    time.sleep(5)

    machine.systemctl("start peer-observer-metrics.service")
    machine.wait_for_unit("peer-observer-metrics.service", timeout=15)
    machine.wait_for_open_port(${toString PEER_OBSERVER_METRICS_PORT})
    metrics = machine.succeed("curl http://127.0.0.1:${toString PEER_OBSERVER_METRICS_PORT}/metrics")
    print(metrics)
    assert "peerobserver_runtime_start_timestamp" in metrics

    machine.systemctl("start peer-observer-addr-connectivity-check.service")
    machine.wait_for_unit("peer-observer-addr-connectivity-check.service", timeout=15)
    machine.wait_for_open_port(${toString PEER_OBSERVER_ADDR_CHECK_METRICS_PORT})

    # right after start up, the addr connectivity check metrics endpoint
    # returns an empty response as no metrics have been set 
    metrics2 = machine.succeed("curl http://127.0.0.1:${toString PEER_OBSERVER_ADDR_CHECK_METRICS_PORT}/metrics")
    assert len(metrics2) == 0

    machine.systemctl("start peer-observer-websocket.service")
    machine.wait_for_unit("peer-observer-websocket.service", timeout=15)
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
