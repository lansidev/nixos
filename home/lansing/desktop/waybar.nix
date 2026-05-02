{ ... }:
{
  programs.waybar = {
    enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "niri/workspaces" "niri/window" ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
          "tray"
        ];

        "niri/workspaces" = {
          format = "{index}";
        };

        "niri/window" = {
          format = "{title}";
          max-length = 60;
        };

        clock = {
          format = "{:%H:%M  %a %d %b}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        cpu = {
          format = "CPU {usage}%";
          interval = 5;
        };

        memory = {
          format = "RAM {percentage}%";
          interval = 5;
        };

        battery = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "BAT {capacity}%";
          format-charging = "BAT {capacity}% +";
          format-plugged = "BAT {capacity}% =";
        };

        network = {
          format-wifi = "{essid} {signalStrength}%";
          format-ethernet = "eth";
          format-disconnected = "no net";
          tooltip-format = "{ifname}: {ipaddr}";
        };

        pulseaudio = {
          format = "VOL {volume}%";
          format-muted = "VOL muted";
          on-click = "pavucontrol";
        };

        tray = {
          spacing = 8;
        };
      };
    };

    style = ''
      * {
        font-family: "Ubuntu", "DejaVu Sans", sans-serif;
        font-size: 12px;
        min-height: 0;
      }

      window#waybar {
        background: rgba(30, 30, 46, 0.9);
        color: #cdd6f4;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      }

      #workspaces button {
        padding: 0 8px;
        background: transparent;
        color: #cdd6f4;
        border-radius: 0;
        border: none;
      }

      #workspaces button.focused,
      #workspaces button.active {
        background: #7fc8ff;
        color: #1e1e2e;
      }

      #workspaces button:hover {
        background: rgba(127, 200, 255, 0.3);
      }

      #window,
      #clock,
      #cpu,
      #memory,
      #battery,
      #network,
      #pulseaudio,
      #tray {
        padding: 0 10px;
      }

      #battery.warning { color: #f9e2af; }
      #battery.critical { color: #f38ba8; }
    '';
  };
}
