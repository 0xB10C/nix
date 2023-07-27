{ config, pkgs, lib, ... }:

with lib;

let
  package = pkgs.callPackage ../../pkgs/github-metadata-backup { };
  eachGithubMetadataBackupInstance = config.services.github-metadata-backup;

  github-metadata-backup-options = { config, lib, name, ... }: {
    options = {
      enable = mkEnableOption (lib.mdDoc "GitHub metadata backup tool");

      package = mkOption {
        type = types.package;
        default = package;
        description = lib.mdDoc "The package providing the github-metadata-backup binary.";
      };

      destination = mkOption {
        type = types.path;
        default = "/var/lib/github-metadata-backup/${name}/";
        description = lib.mdDoc "The destination directory for the JSON files.";
      };

      repository = mkOption {
        type = types.str;
        default = null;
        description = lib.mdDoc "The repository to backup the metadata from";
      };

      owner = mkOption {
        type = types.str;
        default = null;
        description =
          lib.mdDoc "The owner (user or organization) of the repository";
      };

      personalAccessTokenFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/secrets/pat.sec";
        description = lib.mdDoc ''
          Path to a file containing the GitHub personal access token used to
          authenticate against the GitHub API. This is preferred over the
          'personalAccessToken' option'';
      };

      personalAccessToken = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          The GitHub personal access token to use when authentication with the
          GitHub API. This access token will be world-readable so storing the token
          in a file and using 'personalAccessTokenFile' is recommended.'';
      };

      user = mkOption {
        type = types.str;
        default = "gmb-${name}";
        description =
          lib.mdDoc "The user as which to run the github-metadata-backup-tool";
      };

      group = mkOption {
        type = types.str;
        default = "github-metadata";
        description = lib.mdDoc
          "The group as which to run the github-metadata-backup tool.";
      };

      timerOnCalendar = mkOption {
        type = types.str;
        default = "daily";
        description = lib.mdDoc
          "Systemd OnCalendar interval in which the backup job should run.";
      };

    };
  };
in {
  imports = [
    # paths to other modules
  ];

  options = {
    services.github-metadata-backup = mkOption {
      type = types.attrsOf (types.submodule github-metadata-backup-options);
      default = { };
      description = lib.mdDoc
        "Specification of one or more github-metadata-backup instances.";
    };
  };

  config = mkIf (eachGithubMetadataBackupInstance != { }) {
    systemd.services = mapAttrs' (instanceName: cfg:
      (nameValuePair "github-metadata-backup-${instanceName}" ({
        description = "GitHub Metadata Backup ${instanceName}";
        after = [ "network-online.target" ];
        script = ''
          ${cfg.package}/bin/github-meta-backup \
            --owner=${cfg.owner} \
            --repo=${cfg.repository} \
            --destination=${cfg.destination} \
          ${
            optionalString (cfg.personalAccessTokenFile != null)
            "--personal-access-token-file=${cfg.personalAccessTokenFile}"
          }\
          ${optionalString (cfg.personalAccessToken != null)
          "--personal-access-token=${cfg.personalAccessToken}"}

          ${pkgs.git}/bin/git -C ${cfg.destination} init
          ${pkgs.git}/bin/git -C ${cfg.destination} add state.json issues pulls
          ${pkgs.git}/bin/git -C ${cfg.destination} config user.name "${cfg.owner}:${cfg.repository}"
          ${pkgs.git}/bin/git -C ${cfg.destination} config user.email "${cfg.owner}-${cfg.repository}@github-metadata-backup"
          ${pkgs.git}/bin/git -C ${cfg.destination} commit -m "${cfg.owner}:${cfg.repository} GitHub backup from $(date)"
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
      }))) eachGithubMetadataBackupInstance;

    systemd.tmpfiles.rules = flatten (mapAttrsToList (instanceName: cfg:
      [ "d '${cfg.destination}' 0770 '${cfg.user}' '${cfg.group}' - -" ])
      eachGithubMetadataBackupInstance);

    users.users = mapAttrs' (instanceName: cfg:
      (nameValuePair "gmb-${instanceName}" {
        name = cfg.user;
        group = cfg.group;
        description = "GitHub metadata backup user ${instanceName}";
        home = cfg.destination;
        isSystemUser = true;
      })) eachGithubMetadataBackupInstance;

    users.groups =
      mapAttrs' (instanceName: cfg: (nameValuePair "${cfg.group}" { }))
      eachGithubMetadataBackupInstance;

    systemd.timers = mapAttrs' (instanceName: cfg:
      (nameValuePair "github-metadata-backup-${instanceName}" ({
        wantedBy = [ "timers.target" ];
        partOf = [ "github-metadata-backup-${instanceName}.service" ];
        timerConfig.OnCalendar = cfg.timerOnCalendar;
      }))) eachGithubMetadataBackupInstance;

  };

}
