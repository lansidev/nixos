{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    fira-code
    fira-code-symbols
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];
}
