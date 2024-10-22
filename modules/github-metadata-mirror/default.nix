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
        description = lib.mkDoc "Whether to store a compressed copy of the backup in the `wwwDir`.";
      };

      siteName = mkOption {
        type = types.str;
        default = "GitHub Mirror";
        description = lib.mdDoc "The hugo site name. This is displayed as title on the site.";
      };

      siteBaseURL = mkOption {
        type = types.str;
        example = "https://example.com/my-github-metadata-mirror";
        description = lib.mdDoc "The hugo site base URL. This is passed to hugo with the '--baseURL' flag";
      };

      siteFooter = mkOption {
        type = types.str;
        example = "This site is hosted by 0xB10C.";
        default = "This site is hosted by PLACEHOLDER.";
        description = lib.mkDoc "Footer shown in the bottom right. HTML is supported.";
      };

      owner = mkOption {
        type = types.str;
        example = "bitcoin";
        default = null;
        description = lib.mkDoc "Owner of the mirrored repository on GitHub. Used to link to GitHub: https://github.com/<owner>/<repository>";
      };

      repository = mkOption {
        type = types.str;
        example = "bitcoin";
        default = null;
        description = lib.mkDoc "Name of the mirrored repository on GitHub. Used to link to GitHub: https://github.com/<owner>/<repository>";
      };

      goMaxProcs = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = lib.mdDoc "If set, setting the GOMAXPROCS env variable to the value. Can be used to limit the numer of CPUs hugo uses when generating pages.";
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
          lib.mdDoc "The user as which to run the github-metadata-mirror tool";
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
        description = lib.mdDoc "The parent directory of the directory where to generate the HTML files to.";
      };

      package = mkOption {
        type = types.package;
        default = package;
        description = lib.mdDoc "The package providing the github-metadata-mirror binary.";
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

          WORK_DIR=`mktemp -d -t "github-metadata-mirror-XXXXXXXX"`
          if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
            echo "Could not create a temporary directory $WORK_DIR"
            exit 1
          fi

          function cleanup {
            rm -rf "$WORK_DIR"
            echo "Deleted temporary directory $WORK_DIR"
          }
          trap cleanup EXIT

          echo "copy the github-metadata-mirror package contents from ${cfg.package} to $WORK_DIR"
          cp --recursive --no-preserve=ownership,mode ${cfg.package}/* $WORK_DIR

          echo "generate the issue and pull markdown files to the hugo content and data directories from the backup files in ${instanceCfg.backup}"
          ${pkgs.python3}/bin/python ${cfg.package}/generate-data.py ${instanceCfg.backup} $WORK_DIR

          echo "do a hugo build of the site"
          ${pkgs.hugo}/bin/hugo --source $WORK_DIR --logLevel debug --baseURL ${instanceCfg.siteBaseURL}

          echo "deploying to ${cfg.wwwDir}/${instanceName}"
          mkdir -p ${cfg.wwwDir}/${instanceName}
          rm -rf ${cfg.wwwDir}/${instanceName}/*
          mv $WORK_DIR/public/* ${cfg.wwwDir}/${instanceName}

          ${ optionalString instanceCfg.compressBackup ''
            ${pkgs.gnutar}/bin/tar cf - ${instanceCfg.backup} | ${pkgs.xz}/bin/xz > $WORK_DIR/${instanceCfg.owner}-${instanceCfg.repository }.tar.xz
            mv $WORK_DIR/${instanceCfg.owner}-${instanceCfg.repository }.tar.xz ${cfg.wwwDir}/${instanceCfg.owner}-${instanceCfg.repository }.tar.xz
          ''}

        '';
        serviceConfig = {
          User = cfg.user;
          Group = cfg.group;
          Type = "oneshot";
          Environment = ''HUGO_TITLE="${instanceCfg.siteName}" HUGO_PARAMS_OWNER="${instanceCfg.owner}" HUGO_PARAMS_REPOSITORY="${instanceCfg.repository}"  HUGO_PARAMS_FOOTER="${instanceCfg.siteFooter}" ${if isInt instanceCfg.goMaxProcs then ''GOMAXPROCS="${toString instanceCfg.goMaxProcs}"'' else ""}'';

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
