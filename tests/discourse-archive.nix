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

          mirror = {
            enable = true;
            siteUrl = "https://archive.example.com";
          };

          fullResync = {
            enable = true;
            interval = "30d";
          };

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

    # make sure it doesn't start before we want it to start
    machine.systemctl("stop discourse-archive-test.service")

    # this takes absourdly long to start (180s locally and way longer in CI)
    machine.wait_for_unit("discourse.service", timeout = 5000)

    # Wait until discourse is ready to accept connections. This might take another while.
    machine.wait_until_succeeds("""
      status=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:80/posts.json)
      [ "$status" == 200 ]
    """, timeout=500)

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
    print(json.loads(metadata))

    # the mirror step should have rendered a static HTML site
    site = f"{dir}/site"
    print(f"contents of {site}:")
    print(machine.succeed(f"ls -la {site}"))

    machine.succeed(f"stat {site}/index.html")

    # the first run only records the baseline, it must not have forced a
    # full re-sync
    marker = f"{dir}/.last-full-resync"
    machine.succeed(f"stat {marker}")

    # a run well within the interval keeps the metadata around
    machine.succeed(f"touch -d '1 hour ago' {marker}")
    machine.systemctl("start discourse-archive-test.service")
    machine.succeed(f"stat {dir}/.metadata.json")
    machine.succeed(f"[ $(stat -c %Y {marker}) -lt $(date -d '30 minutes ago' +%s) ]")

    # once the interval has passed, .metadata.json is removed before the run
    # and the marker is bumped
    machine.succeed(f"touch -d '60 days ago' {marker}")
    old_metadata = machine.succeed(f"cat {dir}/.metadata.json")
    machine.systemctl("start discourse-archive-test.service")

    journal = machine.succeed("journalctl -u discourse-archive-test.service --no-pager")
    assert "to force a full re-sync" in journal, journal

    machine.succeed(f"[ $(stat -c %Y {marker}) -gt $(date -d '5 minutes ago' +%s) ]")

    # the run recreated it, and archived the same posts again
    new_metadata = machine.succeed(f"cat {dir}/.metadata.json")
    assert json.loads(new_metadata) == json.loads(old_metadata), (old_metadata, new_metadata)

  '';
}
