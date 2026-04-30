{ ... }:
{
  imports = [
    ./cli.nix
    ./direnv.nix
    ./git.nix
    ./golang.nix
    ./kubernetes
    ./neovim.nix
    ./onepassword.nix
    ./tmux
    ./zsh.nix
  ];

  home.username = "lansing";
  home.homeDirectory = "/home/lansing";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
