{ config, pkgs, lib, ... }:

with lib;

let
  package = pkgs.callPackage ../../pkgs/github-metadata-mirror { };
  eachGithubMetadataMirrorInstance = config.services.github-metadata-mirror.mirrors;
  cfg = config.services.github-metadata-mirror;

  github-metadata-mirror-options = { config, lib, name, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "GitHub metadata mirror tool");

      backup = mkOption {
        type = types.path;
        default = "/var/lib/github-metadata-backup/${name}/";
        description = lib.mdDoc "The source directory for the backup JSON files.";
      };

      compressBackup = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether to store a compressed copy of the backup in the `wwwDir`.";
      };

      siteName = mkOption {
        type = types.str;
        default = "GitHub Mirror";
        description = lib.mdDoc "The site title displayed in the navigation bar.";
      };

      siteBaseURL = mkOption {
        type = types.str;
        example = "https://example.com/my-github-metadata-mirror";
        description = lib.mdDoc "The base URL path passed to build.py with --base-url.";
      };

      siteFooter = mkOption {
        type = types.str;
        example = "This site is hosted by 0xB10C.";
        default = "";
        description = lib.mdDoc "Footer HTML shown on every page. HTML is supported.";
      };

      owner = mkOption {
        type = types.str;
        example = "bitcoin";
        description = lib.mdDoc "Owner of the mirrored repository on GitHub.";
      };

      repository = mkOption {
        type = types.str;
        example = "bitcoin";
        description = lib.mdDoc "Name of the mirrored repository on GitHub.";
      };

      timerOnCalendar = mkOption {
        type = types.str;
        default = "daily";
        description = lib.mdDoc
          "Systemd OnCalendar interval in which the mirror build and deploy job should run.";
      };
    };
  };
in {
  options = {
    services.github-metadata-mirror = {
      mirrors = mkOption {
        type = types.attrsOf (types.submodule github-metadata-mirror-options);
        default = { };
        description = lib.mdDoc
          "Specification of one or more github-metadata-mirror jobs.";
      };

      user = mkOption {
        type = types.str;
        default = "github-metadata-backup";
        description =
          lib.mdDoc "The user as which to run the github-metadata-mirror tool.";
      };

      group = mkOption {
        type = types.str;
        default = "github-metadata";
        description = lib.mdDoc
          "The group as which to run the github-metadata-mirror tool.";
      };

      wwwDir = mkOption {
        type = types.path;
        default = "/var/www/github-metadata-mirror";
        description = lib.mdDoc "Parent directory where the generated HTML files are placed.";
      };

      package = mkOption {
        type = types.package;
        default = package;
        description = lib.mdDoc "The package providing the github-metadata-mirror tool.";
      };
    };
  };

  config = mkIf (eachGithubMetadataMirrorInstance != { }) {
    systemd.services = mapAttrs' (instanceName: instanceCfg:
      (nameValuePair "github-metadata-mirror-${instanceName}" ({
        description = "GitHub Metadata Mirror ${instanceName}";
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
        script = ''
          set -e

          WORK_DIR=$(mktemp -d -t "github-metadata-mirror-XXXXXXXX")
          if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
            echo "Could not create a temporary directory $WORK_DIR"
            exit 1
          fi

          function cleanup {
            rm -rf "$WORK_DIR"
            echo "Deleted temporary directory $WORK_DIR"
          }
          trap cleanup EXIT

          echo "Building site from backup at ${instanceCfg.backup}"
          ${cfg.package}/bin/github-metadata-mirror \
            --input ${instanceCfg.backup} \
            --output "$WORK_DIR/public" \
            --title ${escapeShellArg instanceCfg.siteName} \
            --owner ${escapeShellArg instanceCfg.owner} \
            --repository ${escapeShellArg instanceCfg.repository} \
            --base-url ${escapeShellArg instanceCfg.siteBaseURL} \
            ${optionalString (instanceCfg.siteFooter != "") "--footer ${escapeShellArg instanceCfg.siteFooter}"}

          echo "Deploying to ${cfg.wwwDir}/${instanceName}"
          chmod -R u+w "$WORK_DIR/public"
          mkdir -p ${cfg.wwwDir}/${instanceName}
          rm -rf ${cfg.wwwDir}/${instanceName}/*
          mv "$WORK_DIR/public"/* ${cfg.wwwDir}/${instanceName}

          ${optionalString instanceCfg.compressBackup ''
            ${pkgs.gnutar}/bin/tar cf - ${instanceCfg.backup} | ${pkgs.xz}/bin/xz > "$WORK_DIR/${instanceCfg.owner}-${instanceCfg.repository}.tar.xz"
            mv "$WORK_DIR/${instanceCfg.owner}-${instanceCfg.repository}.tar.xz" ${cfg.wwwDir}/${instanceCfg.owner}-${instanceCfg.repository}.tar.xz
          ''}
        '';
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          Type = "oneshot";

          # Hardening measures
          PrivateTmp = "true";
          ProtectSystem = "full";
          NoNewPrivileges = "true";
          PrivateDevices = "true";
          MemoryDenyWriteExecute = "true";
        };
      }))) eachGithubMetadataMirrorInstance;

    systemd.timers = mapAttrs' (instanceName: cfg:
      (nameValuePair "github-metadata-mirror-${instanceName}" ({
        wantedBy = [ "timers.target" ];
        partOf = [ "github-metadata-mirror-${instanceName}.service" ];
        timerConfig.OnCalendar = cfg.timerOnCalendar;
      }))) eachGithubMetadataMirrorInstance;

    systemd.tmpfiles.rules = [
      "d '${cfg.wwwDir}' 0775 '${cfg.user}' '${cfg.group}' - -"
    ];

    users.users."${cfg.user}" = {
      name = cfg.user;
      group = cfg.group;
      description = "GitHub metadata mirror user";
      home = "${cfg.wwwDir}";
      isSystemUser = true;
    };
    users.groups."${cfg.group}" = {};
  };
}
