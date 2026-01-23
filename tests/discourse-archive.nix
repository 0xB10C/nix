{ pkgs, ... }:

let
  hostname = "127.0.0.1:80";
in
{
  name = "discourse-archive";

  nodes.machine =
    { config, lib, ... }:
    {
      imports = [ ../modules/discourse-archive/default.nix ];

      virtualisation.cores = 2;
      virtualisation.memorySize = 2048;

      services.discourse-archive = {
        test = {
          url = "http://${hostname}";
          debug = true;

          timer = {
            enable = true;
            # set this for the tests, but make sure it never fires
            onCalendar = "2000-01-01 00:00:00";
            randomizedDelaySec = "1h";
          };
        };

      };

      services.postgresql.package = pkgs.postgresql_17;

      environment.etc.discourse-test-password.text = "test password";

      services.discourse = {
        enable = true;
        hostname = hostname;
        database = {
          ignorePostgresqlVersion = true;
        };
        admin = {
          email = "admin@example.com";
          fullName = "Admin";
          username = "admin";
          passwordFile = "/etc/discourse-test-password";
        };
        enableACME = false;
        siteSettings = {
          required = {
            title = "test discourse forum";
            site_description = "A test forum.";
          };
        };
      };

    };


  testScript = ''
    import json

    # this takes absourdly long to start (180s on my laptop and way longer in CI)
    machine.wait_for_unit("discourse.service", timeout = 5000)

    machine.wait_for_open_port(80, timeout = 10)

    # Wait until discourse is ready to accept connections. This might take a while.
    machine.wait_until_succeeds("""
      status=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:80)
      [ "$status" != 502 ]
    """, timeout=300)

    machine.succeed("curl -f http://localhost:80")

    machine.systemctl("start discourse-archive-test.service")

    dir = "/var/lib/discourse-archive/test"
    print(f"contents of {dir}:")
    print(machine.succeed(f"ls -la {dir}"))

    machine.succeed(f"stat {dir}/posts")
    machine.succeed(f"stat {dir}/rendered-topics")
    machine.succeed(f"stat {dir}/.metadata.json")

    metadata = machine.succeed(f"cat {dir}/.metadata.json")
    print(".metadata.json:", metadata)

    # we should be able to load the metadata
    json.loads(metadata)

  '';
}
