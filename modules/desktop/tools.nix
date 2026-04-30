{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
    waybar
    swaylock
    mako
    wl-clipboard
    grim
    slurp
    brightnessctl
    pamixer
    playerctl
    libnotify
  ];
}
