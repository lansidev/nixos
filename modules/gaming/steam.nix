{ ... }:
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  hardware.graphics.enable32Bit = true;

  # Steam runs through XWayland (xwayland-satellite); niri reports the
  # X11 WM_CLASS as the app-id. The main client window is `Steam`,
  # while the small login/update splash uses `steam` — the regex
  # catches both. Game windows have their own app-ids and are not
  # captured by this rule, which matches what we want: the launcher
  # lives on `gaming`, individual games stay wherever they're spawned.
  lansing.desktop.niri.appWindowRules = [
    {
      match.app-id = "^[Ss]team$";
      openOnWorkspace = "gaming";
    }
  ];
}
