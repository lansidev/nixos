{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.discord ];

  lansing.desktop.niri.appWindowRules = [
    {
      match.app-id = "^discord$";
      openOnWorkspace = "communication";
    }
  ];
}
