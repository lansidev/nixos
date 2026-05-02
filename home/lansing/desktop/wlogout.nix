{ pkgs, ... }:
{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "swaylock";
        text = "Lock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "niri msg action quit --skip-confirmation";
        text = "Logout";
        keybind = "e";
      }
      {
        label = "suspend";
        action = "systemctl --no-block suspend";
        text = "Suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl --no-block hibernate";
        text = "Hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl --no-block reboot";
        text = "Reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl --no-block poweroff";
        text = "Shutdown";
        keybind = "s";
      }
    ];

    style = ''
      * {
        background-image: none;
        box-shadow: none;
        font-family: "Ubuntu", "DejaVu Sans", sans-serif;
      }

      window {
        background-color: rgba(30, 30, 46, 0.92);
      }

      button {
        color: #cdd6f4;
        font-size: 18px;
        background-color: rgba(30, 30, 46, 0.6);
        border-style: solid;
        border-width: 2px;
        border-color: #7fc8ff;
        border-radius: 16px;
        margin: 64px;
        background-repeat: no-repeat;
        background-position: center 30%;
        background-size: 96px 96px;
      }

      button:focus, button:active, button:hover {
        background-color: rgba(127, 200, 255, 0.25);
        border-color: #cdd6f4;
        outline-style: none;
      }

      #lock {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
      }
      #logout {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
      }
      #suspend {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
      }
      #hibernate {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
      }
      #reboot {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
      }
      #shutdown {
        background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
      }
    '';
  };
}
