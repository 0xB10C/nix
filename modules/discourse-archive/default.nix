{ lib, pkgs, config, ... }:

let
  cfg = config.services.discourse-archive;
  pkg = (pkgs.callPackage ../.. { }).discourse-archive;
  hardening = import ../hardening.nix;

  # discourse-archive only fetches posts newer than the last_sync_date it
  # records in .metadata.json, so topics that were unlisted/hidden while a
  # previous run happened and are visible again now are never picked up.
  # Removing .metadata.json makes the next run re-fetch everything.
  mkFullResyncScript = name: instanceCfg: workDir:
    pkgs.writeShellScript "discourse-archive-${name}-full-resync" ''
      set -eu

      metadata="${workDir}/.metadata.json"
      marker="${workDir}/.last-full-resync"

      # systemd-analyze prints the timespan in microseconds on its second
      # line, labelled "μs:" or, depending on the locale, "us:".
      interval=$(( $(${config.systemd.package}/bin/systemd-analyze timespan ${
        lib.escapeShellArg instanceCfg.fullResync.interval
      } | ${pkgs.gnused}/bin/sed -n '/s:/ { s/[^0-9]//g; p; q; }') / 1000000 ))

      if [ ! -e "$marker" ]; then
        # First run since full re-syncs were enabled. Treat the archive as it
        # is now as the baseline rather than forcing an immediate full re-sync.
        ${pkgs.coreutils}/bin/touch "$marker"
        exit 0
      fi

      age=$(( $(${pkgs.coreutils}/bin/date +%s) - $(${pkgs.coreutils}/bin/stat -c %Y "$marker") ))

      if [ "$age" -ge "$interval" ]; then
        echo "last full re-sync was ''${age}s ago (interval ''${interval}s), removing $metadata to force a full re-sync"
        ${pkgs.coreutils}/bin/rm -f "$metadata"
        ${pkgs.coreutils}/bin/touch "$marker"
      else
        echo "last full re-sync was ''${age}s ago (interval ''${interval}s), doing an incremental sync"
      fi
    '';

  mkService = name: instanceCfg:
    let

      workDir =
        if instanceCfg.targetDir != null
        then instanceCfg.targetDir
        else "/var/lib/discourse-archive/${name}";

      mirrorOutputDir =
        if instanceCfg.mirror.outputDir != null
        then instanceCfg.mirror.outputDir
        else "${workDir}/site";
    in
    {
      name = "discourse-archive-${name}";
      value = {
        description = "Discourse Archive Generator (${name})";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = hardening.default // hardening.allowAllIPAddresses // {
          Type = "oneshot";
          # Force a full re-sync every now and then, see mkFullResyncScript.
          ExecStartPre = lib.optional instanceCfg.fullResync.enable
            (mkFullResyncScript name instanceCfg workDir);
          ExecStart = "${instanceCfg.package}/bin/discourse-archive --url ${instanceCfg.url} --target-dir ${instanceCfg.targetDir}"; # note: --debug is broken
          # Render a static HTML mirror from the freshly written archive.
          ExecStartPost = lib.optional instanceCfg.mirror.enable (
            "${instanceCfg.package}/bin/discourse-mirror --url ${instanceCfg.url} --target-dir ${instanceCfg.targetDir} --output-dir ${mirrorOutputDir}"
            + lib.optionalString (instanceCfg.mirror.siteUrl != null) " --site-url ${instanceCfg.mirror.siteUrl}"
          );
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

        mirror = {
          enable = lib.mkEnableOption "rendering a static HTML mirror from the archive after each run";

          outputDir = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "/var/lib/discourse-archive/example/site";
            description = ''
              Directory the rendered static HTML mirror is written to.

              Defaults to a "site" subdirectory of the archive's target
              directory.
            '';
          };

          siteUrl = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "https://archive.example.com";
            description = ''
              URL where the mirror itself will be deployed (used for og:url
              tags). Optional.
            '';
          };
        };

        fullResync = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            example = false;
            description = ''
              Periodically force a full re-sync instead of only fetching posts
              newer than the last sync.

              Incremental syncs miss topics that were unlisted or hidden while
              an earlier run happened and have become visible again since. A
              full re-sync picks those up.
            '';
          };

          interval = lib.mkOption {
            type = lib.types.str;
            default = "30d";
            example = "12h";
            description = ''
              How much time has to pass between two full re-syncs, as a
              systemd.time time span.

              The time of the last full re-sync is tracked in a
              ".last-full-resync" file in the target directory. The first run
              after enabling this only creates that file, so enabling the
              option does not trigger an immediate full re-sync.
            '';
          };
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
