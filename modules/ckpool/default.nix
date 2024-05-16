{ config, lib, pkgs, ... }:

with lib;

let
  pkg = (pkgs.callPackage ../.. { }).ckpool;
  cfg = config.services.ckpool;
  #hardening = import ../systemd-hardening.nix { };

in {
  options = {

    services.ckpool = {
      enable = mkEnableOption "ckpool";

      package = mkOption {
        type = types.package;
        default = pkg;
        description = "The ckpool package to use.";
      };

      address = mkOption {
        type = types.str;
        default = "127.0.0.1:3882";
        description = "Address the pool listens on";
      };

      coinbaseTag = mkOption {
        type = types.str;
        default = "/mined by ck/";
        description = "Coinbase tag";
      };

      iam_not_using_this_to_mine = mkOption {
        type = types.bool;
        default = false;
        description = "This ckpool module is not intended to be used for real mining. This is a reminder.";
      };

      rpc = {
        host = mkOption {
          type = types.str;
          default = "localhost";
          example = "localhost";
          description = lib.mdDoc "The Bitcoin Core RPC host to use.";
        };

        port = mkOption {
          type = types.port;
          default = 8332;
          example = 18884;
          description = lib.mdDoc "The Bitcoin Core RPC port to use.";
        };

        password = mkOption {
          type = types.str;
          default = null;
          description = lib.mdDoc
            "The Bitcoin Core RPC password to use. This will be world-readable!";
        };

        user = mkOption {
          type = types.str;
          default = null;
          example = "username";
          description = lib.mdDoc "The Bitcoin Core RPC username to use.";
        };
      };
      
      zmqblock = mkOption {
        type = types.str;
        default = "tcp://127.0.0.1:28332";
        description = lib.mdDoc "The endpoint of the Bitcoin Core ZMQ interface for new blocks.";
      };

    };
  };

  config = mkIf cfg.enable {

    assertions = [{ 
      assertion = cfg.iam_not_using_this_to_mine;
      message = "This ckpool module is not intended to be used for mining coins with real value. Set `iam_not_using_this_to_mine` to true.";
    }];

    users = {
      users.ckpool = {
        isSystemUser = true;
        group = "ckpool";
        home = "/var/lib/ckpool";
      };
      groups.ckpool = { };
    };

    systemd.tmpfiles.rules =
      [ "d '/var/lib/ckpool/' 0770 'ckpool' 'ckpool' - -" ];

    systemd.services.ckpool = {
      description = "ckpool";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      startLimitIntervalSec = 120;
      preStart = ''
        cat <<EOF > /etc/ckpool/ckpool.conf
        {
          "btcd" :  [
          	{
          		"url" : "${cfg.rpc.host}:${toString cfg.rpc.port}",
          		"auth" : "${cfg.rpc.user}",
          		"pass" : "${cfg.rpc.password}",
          		"notify" : true
          	}
          ],
          "upstream" : "",
          "btcaddress" : "1BitcoinEaterAddressDontSendf59kuE",
          "btcsig" : "${cfg.coinbaseTag}",
          "blockpoll" : 100,
          "donation" : 0.0,
          "nonce1length" : 4,
          "nonce2length" : 8,
          "update_interval" : 30,
          "version_mask" : "1fffe000",
          "serverurl" : [
          	"${cfg.address}"
          ],
          "nodeserver" : [],
          "trusted" : [],
          "mindiff" : 1,
          "startdiff" : 42,
          "maxdiff" : 0,
          "zmqblock" : "${cfg.zmqblock}",
          "logdir" : "/var/lib/ckpool/logs"
        }
        # ckpool configuration file
        # auto generated by the ckpool module
        EOF'';

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/ckpool --killold --config /etc/ckpool/ckpool.conf";
        Restart = "always";
        # restart every 30 seconds but fail if we do more than 3 restarts in 120 sec
        RestartSec = 30;
        StartLimitBurst = 3;
        PermissionsStartOnly = true;
        # Needs to be disabled for ckpool to create new pthreads..
        MemoryDenyWriteExecute = false;
        ConfigurationDirectory = "ckpool"; # /etc/ckpool
        ConfigurationDirectoryMode = 710;
        ReadWriteDirectories = "/var/lib/ckpool";
        DynamicUser = true;
        User = "ckpool";
        Group = "ckpool";
      };
    };
  };
}
