# Screen recording / streaming. battlestation only.
{
  flake.modules.nixos.obs-studio = { pkgs, ... }: {
    programs.obs-studio.enable = true;
    environment.systemPackages = [ pkgs.v4l-utils ];
  };
}
