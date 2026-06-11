# Reference: https://docs.noctalia.dev/v4/getting-started/nixos/
{ inputs, ... }:
{
  flake.modules.homeManager.desktop = { config, ... }: {
    imports = [ inputs.noctalia.homeModules.default ];

    programs.noctalia-shell = {
      enable = true;
      settings = {
        colorSchemes = {
          predefinedScheme = "Catppuccin";
          darkMode = true;
          useWallpaperColors = false;
          schedulingMode = "auto";
        };
        location = {
          name = "Düsseldorf, Germany";
          autoLocate = false;
        };
        wallpaper = {
          enabled = true;
          directory = "${config.home.homeDirectory}/Pictures/wallpapers";
        };
        hooks = {
          enabled = true;
          startup = ''noctalia-shell ipc call wallpaper random ""'';
        };
        general.enableShadows = false;
        bar.widgets = {
          left = [
            { id = "Launcher"; }
            {
              id = "Clock";
              # Qt date/time format (case-sensitive, lokalisiert):
              #   ddd  = Wochentag abgekürzt (z.B. "Fr")
              #   d    = Tag ohne führende Null
              #   MMMM = Monat ausgeschrieben (z.B. "Mai")
              #   HH:mm:ss = Stunde:Minute:Sekunde, 24h
              # Ergibt z.B. "Fr. 8. Mai 15:50:39" (de_DE-Locale vorausgesetzt).
              formatHorizontal = "ddd. d. MMMM HH:mm:ss";
              tooltipFormat = "yyyy-MM-dd HH:mm:ss";
            }
            { id = "SystemMonitor"; }
            { id = "ActiveWindow"; maxWidth = 500; }
          ];
          center = [
            {
              id = "Workspace";
              labelMode = "name";
              characterCount = 1;
            }
          ];
          right = [
            { id = "MediaMini"; maxWidth = 500; }
            { id = "Tray"; }
            { id = "NotificationHistory"; }
            { id = "Battery"; }
            { id = "Volume"; }
            { id = "Brightness"; }
            { id = "ControlCenter"; }
          ];
        };
      };
    };
  };
}
