{ pkgs, ... }:

let

  PEER_OBSERVER_METRICS_PORT = 10090;
  PEER_OBSERVER_ADDR_CHECK_METRICS_PORT = 10080;
  PEER_OBSERVER_EXTRACTOR_PORT = 10070;
  PEER_OBSERVER_WEBSOCKET_PORT = 10060;
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
      package = (pkgs.callPackage ./.. { }).bitcoind-tracing-v27; # might needs to be updated from time to time
      port = 12345;
      extraConfig = ''
        regtest=1
        debug=net
      '';
    };
    
    services.peer-observer = {
      extractor = {
        enable = true;
        bitcoindPath = "${config.services.bitcoind.regtest.package}/bin/bitcoind";
        eventsAddress = "tcp://127.0.0.1:${toString PEER_OBSERVER_EXTRACTOR_PORT}";
        # can be removed once https://github.com/bitcoin/bitcoin/pull/25832 is merged
        # and included in a release
        extraArgs = "--no-connection-tracepoints";
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
    # HACK: don't start these from the beginning
    # needs https://github.com/0xB10C/peer-observer/issues/37
    machine.systemctl("stop peer-observer-metrics.service")
    machine.systemctl("stop peer-observer-websocket.service")
    machine.systemctl("stop peer-observer-addr-connectivity-check.service")
  
    machine.wait_for_unit("bitcoind-regtest.service", timeout=15)
    machine.wait_for_open_port(${toString BITCOIND_PORT})
    
    machine.wait_for_unit("peer-observer-extractor.service", timeout=15)
    machine.wait_for_open_port(${toString PEER_OBSERVER_EXTRACTOR_PORT})

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
    machine.wait_for_open_port(${toString PEER_OBSERVER_WEBSOCKET_PORT})
  '';
}
