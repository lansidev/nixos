# workstation — Framework 13 Pro laptop (Intel Core Ultra 7 358H).
{ config, inputs, ... }:
{
  flake.nixosConfigurations.workstation = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = with config.flake.modules.nixos; [
      base
      desktop
      development
      gaming
      laptop
      slack
      ../../hosts/workstation/hardware-configuration.nix
      ../../disko/workstation.nix
      {
        networking.hostName = "workstation";
        system.stateVersion = "25.11";

        lansing.desktop.keyboardLayout = "ansi";

        # eDP-1 is the Framework 13 Pro internal panel (2.8K @ 120 Hz).
        # `niri msg outputs` post-install will report the exact mode
        # string; correct here if it differs.
        lansing.desktop.niriOutputs = ''
          output "eDP-1" {
              mode "2880x1920@120.000"
              scale 1.5
          }
        '';

        # Pin the comms workspace to the laptop panel so Slack/Vesktop
        # always land there even when an external monitor is plugged in.
        lansing.desktop.niri.workspaceOutputs = {
          communication = "eDP-1";
        };
      }
    ];
  };
}
