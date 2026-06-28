# Reference: https://docs.noctalia.dev/v5/getting-started/nixos/
#
# Config model (matters for keeping this in git): the home-manager module writes
# `settings` to ~/.config/noctalia/config.toml as a READ-ONLY symlink into the
# Nix store (xdg.configFile, exactly like niri.kdl). That file is the declarative
# base and is fully git-synced — editing it here is the source of truth.
#
# BUT Noctalia layers a second file on top at runtime:
# ~/.local/state/noctalia/settings.toml. Its C++ core merges the config-dir
# *.toml first, then deep-merges that state file OVER it (verified in
# config_validate.cpp `mergeSources`), so the state file WINS. Every change made
# in the Noctalia UI (theme, bar, wallpaper selection, dragged lockscreen
# widgets, …) is persisted there — NOT here, NOT in git. Consequences:
#   * UI tweaks never flow back to the repo (one-way drift), and
#   * once a key exists in settings.toml it permanently shadows the value we set
#     here, even across rebuilds.
# We deliberately do NOT symlink that state file read-only: it also holds
# genuinely runtime state (current wallpaper per monitor, widget positions) the
# UI must be able to write. Discipline instead: manage anything that should be
# declarative HERE and avoid changing it in the UI. If a setting below stops
# taking effect, it has been shadowed — delete that key from
# ~/.local/state/noctalia/settings.toml. (See TODO.md: audit all self-authored
# modules for this declarative-vs-mutable split.)
{ inputs, ... }:
{
  flake.modules.homeManager.desktop = { config, ... }: {
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia = {
      enable = true;
      # Nix attrset serialised to TOML and linked read-only into the store as
      # ~/.config/noctalia/config.toml (the declarative base; see the header for
      # how the runtime settings.toml overlays this).
      settings = {
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
        };
        location = {
          address = "Düsseldorf, Germany";
          auto_locate = false;
        };
        wallpaper = {
          enabled = true;
          directory = "${config.home.homeDirectory}/Pictures/wallpapers";
        };
        hooks.started = "noctalia msg wallpaper-random";
        # v5 dropped the global shadow toggle; alpha = 0 keeps shadows off.
        shell.shadow.alpha = 0;

        bar.main = {
          start = [ "launcher" "clock" "sysmon" "active_window" ];
          center = [ "workspaces" ];
          end = [ "media" "tray" "notifications" "battery" "volume" "brightness" "control-center" ];
        };

        # Per-widget settings live in their own tables in v5 (no longer inline
        # on each bar entry).
        widget = {
          clock = {
            # Python strftime (renders in the process locale = en_US, so the
            # weekday/month names come out English):
            #   %a = weekday abbreviated, %-d = day without leading zero,
            #   %B = month spelled out, %H:%M:%S = 24h time.
            format = "{:%a. %-d. %B %H:%M:%S}";
            tooltip_format = "{:%Y-%m-%d %H:%M:%S}";
          };
          active_window.max_length = 500;
          media.max_length = 500;
          # "id" labels each workspace with its numeric index (1, 2, 3, …).
          # "name" instead shows the workspace name truncated to
          # max_label_chars (default 1), which rendered named niri workspaces
          # as single letters (passwords→p, code→c, …) mixed with bare numbers.
          workspaces.display = "id";
        };
      };
    };
  };
}
