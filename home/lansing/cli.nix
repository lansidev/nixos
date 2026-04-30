{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    yq-go
    tree
    htop
    file
  ];
}
