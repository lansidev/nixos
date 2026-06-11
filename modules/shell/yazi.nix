{
  flake.modules.homeManager.base = {
    # Blazing-fast TUI file manager (https://github.com/sxyazi/yazi).
    # `enableZshIntegration` ships the `yy` shell wrapper: it launches yazi,
    # and on quit cd's the parent shell to the directory yazi left off in
    # (plain `yazi` can't change the shell's cwd; the wrapper reads its
    # `--cwd-file` and `builtin cd`s there). Note the name is `yy`, not `y`.
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  # Image handling. Alacritty implements no inline image protocol (no Kitty
  # graphics / Sixel / iTerm2), so yazi's built-in preview falls back to the
  # `Halfblock` adapter — coarse, visibly pixelated bitmaps (one cell = 2px
  # tall). There is no yazi setting that makes that crisp; the fix is to open
  # the file in a real GUI viewer instead. Enter/`o` on an image now launches
  # imv (Wayland-native, fits Niri), which renders the full-resolution image.
  #
  # Lives in `desktop` (not `base`) because imv is a GUI app — a headless host
  # shouldn't pull in the Wayland dependency. Both current hosts are desktops,
  # and the option merges with the `programs.yazi.enable` set above.
  flake.modules.homeManager.desktop =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.imv ];
      programs.yazi.settings = {
        opener.image = [
          {
            # orphan = detach imv from yazi so quitting yazi doesn't kill the
            # viewer and yazi returns to the file list immediately.
            run = ''imv "$@"'';
            orphan = true;
            desc = "Open in imv";
            "for" = "unix";
          }
        ];
        # prepend (not replace) so this rule wins for images via first-match,
        # while every other filetype keeps yazi's default openers.
        open.prepend_rules = [
          {
            mime = "image/*";
            use = "image";
          }
        ];
      };
    };
}
