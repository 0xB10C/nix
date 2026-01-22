{ lib, pkgs, config, ... }:

let
  cfg = config.services.discourse-archive;
  pkg = (pkgs.callPackage ../.. { }).discourse-archive;
  hardening = import ../hardening.nix;

  mkService = name: instanceCfg:
    let

      workDir =
        if instanceCfg.targetDir != null
        then instanceCfg.targetDir
        else "/var/lib/discourse-archive/${name}";
    in
    {
      name = "discourse-archive-${name}";
      value = {
        description = "Discourse Archive Generator (${name})";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          Type = "oneshot";
          ExecStart = "${instanceCfg.package}/bin/discourse-archive --url ${instanceCfg.url} --target-dir ${instanceCfg.targetDir}"; # note: --debug is broken
          Environment = (lib.optionalString instanceCfg.debug "DEBUG=true");
          DynamicUser = true;
          StateDirectory = "discourse-archive/${name}";
          WorkingDirectory = workDir;
        };
      };
    };

  mkTimer = name: instanceCfg:
    let
      serviceName = "discourse-archive-${name}";
    in
    lib.optionalAttrs instanceCfg.timer.enable {
      "${serviceName}" = {
        description = "Timer for ${serviceName}";
        wantedBy = [ "timers.target" ];

        timerConfig = {
          OnCalendar = instanceCfg.timer.onCalendar;
          RandomizedDelaySec = instanceCfg.timer.randomizedDelaySec;
          Persistent = true;
          Unit = "${serviceName}.service";
        };
      };
    };
in
{
  options.services.discourse-archive = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
      options = {
        package = lib.mkOption {
          type = lib.types.package;
          default = pkg;
          description = "The discourse-archive package to use.";
        };

        url = lib.mkOption {
          type = lib.types.str;
          default = null;
          example = "https://discourse.example.com";
          description = "URL of the Discourse server to archive.";
        };

        debug = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable debug logging.";
        };

        targetDir = lib.mkOption {
          type = lib.types.path;
          default = "/var/lib/discourse-archive/${name}";
          example = "/var/lib/discourse-archive/example";
          description = "Target directory for the archive.";
        };

        timer = {
          enable = lib.mkEnableOption "periodic execution via systemd timer";

          onCalendar = lib.mkOption {
            type = lib.types.str;
            default = "daily";
            example = "Mon..Fri 01:00";
            description = ''
              systemd.time OnCalendar expression.

              Defaults to "daily" (midnight UTC).
            '';
          };

          randomizedDelaySec = lib.mkOption {
            type = lib.types.str;
            default = "2h";
            example = "30m";
            description = ''
              Randomized delay added to the scheduled time.
            '';
          };
        };

      };
    }));
    default = { };
    description = "Named discourse-archive instances.";
  };


  config = {
    systemd.services =
      lib.mapAttrs' mkService cfg;

    systemd.timers =
      lib.mkMerge (
        lib.mapAttrsToList mkTimer cfg
      );
  };
}
