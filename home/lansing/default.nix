{ pkgs, ... }:
{
  imports = [
    ./cli.nix
    ./onepassword.nix
    ./shell
    ./development
    ./desktop
  ];

  home.username = "lansing";
  home.homeDirectory = "/home/lansing";
  home.stateVersion = "25.11";

  # Adwaita's xcursor only ships sizes 24/30/36/48/72/96, so any size <24
  # silently rounds up to 24 (= niri's default). Catppuccin mocha dark adds
  # 12/18 at the small end and matches the Catppuccin scheme used elsewhere.
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaDark;
    name = "catppuccin-mocha-dark-cursors";
    size = 16;
    gtk.enable = true;
  };

  programs.home-manager.enable = true;
}
