{ ... }:
{
  programs.fuzzel = {
    enable = true;

    settings = {
      main = {
        font = "sans-serif:size=14";
        lines = 12;
        width = 40;
        horizontal-pad = 16;
        vertical-pad = 12;
        inner-pad = 8;
        line-height = 22;
        layer = "overlay";
        terminal = "alacritty";
        icon-theme = "hicolor";
      };

      colors = {
        background = "1e1e2eee";
        text = "cdd6f4ff";
        match = "7fc8ffff";
        selection = "7fc8ffff";
        selection-text = "1e1e2eff";
        selection-match = "1e1e2eff";
        border = "7fc8ffff";
      };

      border = {
        width = 2;
        radius = 8;
      };
    };
  };
}
