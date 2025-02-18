{
  default = {
    PrivateTmp = "true";
    ProtectSystem = "strict";
    ProtectHome = "true";
    NoNewPrivileges = "true";
    PrivateDevices = "true";
    MemoryDenyWriteExecute = "true";
    ProtectKernelTunables = "true";
    ProtectKernelModules = "true";
    ProtectKernelLogs = "true";
    ProtectClock = "true";
    ProtectProc = "invisible";
    ProcSubset = "pid";
    ProtectControlGroups = "true";
    RestrictNamespaces = "true";
    LockPersonality = "true";
    IPAddressDeny = "any";
    PrivateUsers = "true";
    RestrictSUIDSGID = "true";
    RemoveIPC = "true";
    RestrictRealtime = "true";
    ProtectHostname = "true";
    CapabilityBoundingSet = "";
    # @system-service whitelist and docker seccomp blacklist (except for "clone"
    # which is a core requirement for systemd services)
    # @system-service is defined in src/shared/seccomp-util.c (systemd source)
    SystemCallFilter = [
      "@system-service"
      "~add_key get_mempolicy kcmp keyctl mbind move_pages name_to_handle_at personality process_vm_readv process_vm_writev request_key set_mempolicy setns unshare userfaultfd"
      "clone3"
    ];
    SystemCallArchitectures = "native";
  };

  # Allow takes precedence over Deny.
  allowLocalIPAddresses = {
    IPAddressAllow = [
      "127.0.0.1/32"
      "::1/128"
      "169.254.0.0/16"
    ];
  };
  
  allowAllIPAddresses = {
    IPAddressAllow = "any";
  };
}
