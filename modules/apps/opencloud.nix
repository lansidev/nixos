{
  flake.modules.nixos.desktop = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.opencloud-desktop ];
  };

  # opencloud-desktop is a Qt app: bin/opencloud is a wrapper that exports
  # NIXPKGS_QT6_QML_IMPORT_PATH / QT_PLUGIN_PATH (so Qt finds qtquickcontrols2plugin)
  # and then exec's the real binary, bin/.opencloud-wrapped. When OpenCloud's
  # "launch on system startup" registers itself in ~/.config/autostart, it
  # records the *running* executable path — which is the unwrapped .opencloud-wrapped
  # (the wrapper exec'd into it). At the next login niri spawns that raw binary
  # without the Qt env, so QtQuick.Controls fails to load and a "qtquickcontrols2plugin
  # not found" error window pops up. We own the autostart entry declaratively and
  # point it at the wrapper; home-manager writes it as a read-only store symlink,
  # so OpenCloud can no longer clobber it with the broken path.
  flake.modules.homeManager.desktop = { pkgs, ... }: {
    xdg.configFile."autostart/OpenCloud.desktop".text = ''
      [Desktop Entry]
      Name=OpenCloud Desktop
      GenericName=File Synchronizer
      Exec=${pkgs.opencloud-desktop}/bin/opencloud
      Terminal=false
      Icon=opencloud
      Categories=Network
      Type=Application
      StartupNotify=false
      X-GNOME-Autostart-enabled=true
      X-GNOME-Autostart-Delay=10
    '';
  };
}
