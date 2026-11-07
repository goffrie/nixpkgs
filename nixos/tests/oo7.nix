{ pkgs, ... }:
{
  name = "oo7";
  meta = { inherit (pkgs.oo7.meta) maintainers; };

  nodes.machine =
    { lib, ... }:
    {
      services.oo7.enable = true;

      users.users.alice = {
        isNormalUser = true;
        uid = 1000;
        password = "foobar";
      };

      # don't launch oo7-daemon automatically, we will launch it ourselves during the test
      systemd.user.services.oo7-daemon.wantedBy = lib.mkForce [ ];
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_until_succeeds("pgrep -f 'agetty.*tty1'")

    with subtest("Log in as alice"):
        machine.wait_until_tty_matches("1", "login: ")
        machine.send_chars("alice\n")
        machine.wait_until_tty_matches("1", "Password: ")
        machine.send_chars("foobar\n")
        machine.wait_until_succeeds("pgrep -u alice bash")

    with subtest("oo7-daemon unlocks the login keyring"):
        # deterministically launch oo7-daemon *after* PAM authentication
        machine.succeed("systemctl --user -M alice@ start oo7-daemon.service")

        collection = machine.succeed(
            "busctl --user -M alice@ call org.freedesktop.secrets /org/freedesktop/secrets org.freedesktop.Secret.Service ReadAlias s default",
        ).split()[1].strip('"')
        assert collection != "/", "no default collection"

        locked = machine.succeed(
            f"busctl --user -M alice@ get-property org.freedesktop.secrets {collection} org.freedesktop.Secret.Collection Locked",
        ).strip()
        assert locked == "b false", f"login keyring is not unlocked: {locked}"
  '';
}
