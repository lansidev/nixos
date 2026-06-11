# Home-manager wiring for the single user `lansing`, plus the user's
# core identity. This is the bridge between the NixOS buckets and their
# home-manager counterparts: a host that imports nixos.<bucket> gets
# homeManager.<bucket> applied to lansing automatically.
{ config, inputs, ... }:
{
  flake.modules.nixos.base = {
    imports = [ inputs.home-manager.nixosModules.home-manager ];
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.lansing.imports = [ config.flake.modules.homeManager.base ];
  };

  flake.modules.nixos.desktop.home-manager.users.lansing.imports =
    [ config.flake.modules.homeManager.desktop ];
  flake.modules.nixos.development.home-manager.users.lansing.imports =
    [ config.flake.modules.homeManager.development ];

  flake.modules.homeManager.base = { pkgs, ... }: {
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
  };
}
