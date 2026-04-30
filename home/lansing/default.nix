{ ... }:
{
  imports = [
    ./cli.nix
    ./onepassword.nix
    ./shell
    ./development
  ];

  home.username = "lansing";
  home.homeDirectory = "/home/lansing";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
