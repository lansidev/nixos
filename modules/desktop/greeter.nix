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
  flake.modules.nixos.desktop = { config, pkgs, ... }: {
    imports = [ inputs.noctalia-greeter.nixosModules.default ];

    programs.noctalia-greeter = {
      enable = true;
      # `package` is intentionally left at the module default: the flake's
      # nixosModule wires it to its own derivation, built against our stable
      # `nixpkgs` via the input's `follows` (see flake.nix).

      # greetd starts greeters with an empty environment, so the compositor
      # cannot inherit XKB_DEFAULT_* or XCURSOR_* — anything that must match the
      # desktop has to be pinned in greeter.toml here.
      #
      # Caveat: the upstream module writes this via systemd-tmpfiles `C`
      # (copy-once) to /var/lib/noctalia-greeter/greeter.toml so the greeter can
      # persist its own last-used session/scheme. Editing the settings below
      # therefore only takes effect on a machine that has no greeter.toml yet —
      # to re-apply after a change, delete that file and rebuild.
      settings = {
        # Login keymap follows the physical layout (host.desktop.keyboardLayout),
        # the same iso->de / ansi->us mapping niri's xkb and the TTY console use,
        # so the password is typed with the layout the user expects.
        keyboard.layout =
          if config.host.desktop.keyboardLayout == "iso" then "de" else "us";

        # Match the desktop pointer from modules/users/home-base.nix. The greeter
        # runs as the `greeter` user with no XCURSOR_PATH, so point it at the
        # theme's store path explicitly rather than relying on a search path.
        cursor = {
          theme = "catppuccin-mocha-dark-cursors";
          size = 16;
          path = "${pkgs.catppuccin-cursors.mochaDark}/share/icons";
        };
      };
    };
  };
}
