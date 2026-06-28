# Auto-lock the session when the machine sits untouched. niri implements the
# ext-idle-notify-v1 Wayland protocol, so swayidle (a wlroots-style idle
# daemon) can watch for inactivity and fire the Noctalia lock screen — the
# same lock reached manually via Mod+Alt+L (`noctalia msg session lock` in
# modules/desktop/niri.kdl).
#
# Home-Manager renders this into a systemd user service bound to
# graphical-session.target, so it starts and stops with the niri session —
# matching how xwayland-satellite / hyprpolkitagent are wired on the NixOS
# side in modules/desktop/niri.nix.
{
  flake.modules.homeManager.desktop = { config, ... }:
    let
      # Absolute path rather than a bare `noctalia`: the systemd user service's
      # PATH is not guaranteed to carry the per-user profile bin, and the store
      # path is what `config.programs.noctalia.package` (set by the Noctalia HM
      # module) resolves to anyway.
      lock = "${config.programs.noctalia.package}/bin/noctalia msg session lock";
    in
    {
      services.swayidle = {
        enable = true;

        # Lock after 5 minutes (300 s) of no keyboard/pointer activity.
        timeouts = [
          { timeout = 300; command = lock; }
        ];

        # Also lock before the system suspends — an unattended machine that
        # sleeps should come back to the lock screen, not the live session.
        # `lock` additionally bridges logind's lock signal, so
        # `loginctl lock-session` engages the Noctalia lock too.
        events = {
          before-sleep = lock;
          lock = lock;
        };
      };
    };
}
