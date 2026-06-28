# Reference: https://github.com/noctalia-dev/noctalia-greeter
#
# Noctalia Greeter is the greetd login screen, in place of ReGreet. It is NOT a
# GTK app hosted by `cage`; it ships its own wlroots compositor
# (`noctalia-greeter-compositor`) and the greeter renders inside it. Enabling
# the module flips on `services.greetd` and points `default_session.command`
# (via mkDefault) at `${pkg}/bin/noctalia-greeter-session`, which launches that
# compositor. greetd's own NixOS module still creates the `greeter` user and
# defaults `default_session.user` to it, so authentication goes through the
# `greetd` PAM service (keyring unlock wired in modules/desktop/keyring.nix).
#
# niri's wayland-session desktop file (installed by `programs.niri`) shows up in
# the greeter's session picker (F3) automatically. We don't pin a default
# session: niri is the only one, so the greeter selects it on its own.
{ inputs, ... }:
{
  flake.modules.nixos.desktop = { config, pkgs, ... }:
    let
      # Built from ./greeter.toml exactly the way niri.kdl is (readFile +
      # replaceStrings over @MARKERS@): a real, reviewable config file in the
      # repo turned into a read-only store file. The greeter is a system service
      # under the `greeter` user, so there is no home-manager xdg.configFile to
      # symlink it for us — we do the substitution and the symlink (below)
      # ourselves. The cursor values mirror modules/users/home-base.nix; they are
      # repeated here because that pointer is defined in home-manager scope, out
      # of reach of this NixOS module.
      greeterToml = pkgs.writeText "greeter.toml" (builtins.replaceStrings
        [ "@KEYMAP@" "@CURSOR_THEME@" "@CURSOR_SIZE@" "@CURSOR_PATH@" ]
        [
          (if config.host.desktop.keyboardLayout == "iso" then "de" else "us")
          "catppuccin-mocha-dark-cursors"
          "16"
          "${pkgs.catppuccin-cursors.mochaDark}/share/icons"
        ]
        (builtins.readFile ./greeter.toml));
    in
    {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      # `package` stays at the module default: the flake's nixosModule wires it
      # to its own derivation, built against our stable `nixpkgs` (see flake.nix).
      #
      # `settings` is deliberately left empty. Were it set, the upstream module
      # would copy it *once* (systemd-tmpfiles `C`) into the mutable
      # /var/lib/noctalia-greeter/greeter.toml — so later edits would never
      # re-apply and the two hosts could silently drift. Instead we point that
      # path straight at the read-only store file below: fully declarative,
      # identical on every machine, and authoritative on every rebuild.
      programs.noctalia-greeter.enable = true;

      # The greeter reads (and, on UI session/scheme changes, would write)
      # /var/lib/noctalia-greeter/greeter.toml. `L+` force-replaces that path on
      # every activation with a symlink to the store, so the declarative version
      # always wins and the stale copy left by an earlier `settings = { … }` is
      # cleaned up automatically — no manual `rm` needed. The trade-off: the
      # greeter can no longer persist its last-used session/scheme (it would try
      # to write the read-only store file and just logs a warning), which is fine
      # here — there is one session (niri) and the cursor/keymap are fixed.
      # The module's own tmpfiles rule still creates the parent dir.
      systemd.tmpfiles.settings."20-noctalia-greeter-toml"."/var/lib/noctalia-greeter/greeter.toml"."L+" = {
        argument = "${greeterToml}";
      };
    };
}
