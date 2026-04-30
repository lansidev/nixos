{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ripgrep
    fd
    bat
    eza
    jq
    fzf
  ];
}
