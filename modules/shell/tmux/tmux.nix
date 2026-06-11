{
  flake.modules.homeManager.base = { pkgs, ... }:
    let
      # Pinned to gpakosz/.tmux master at 2026-02-21. Bump rev + hash with:
      #   nix-prefetch-url --unpack https://github.com/gpakosz/.tmux/archive/<rev>.tar.gz
      #   nix hash convert --hash-algo sha256 --to sri <base32>
      oh-my-tmux = pkgs.fetchFromGitHub {
        owner = "gpakosz";
        repo = ".tmux";
        rev = "af33f07134b76134acca9d01eacbdecca9c9cda6";
        hash = "sha256-nXm664l84YSwZeRM4Hsweqgz+OlpyfwXcgEdyNGhaGA=";
      };
    in
    {
      home.packages = [ pkgs.tmux ];

      # gpakosz/.tmux ships a self-contained .tmux.conf that sources
      # ~/.tmux.conf.local for user overrides. Both files live at $HOME (not
      # under XDG) because that's what the upstream config expects.
      home.file = {
        ".tmux.conf".source = "${oh-my-tmux}/.tmux.conf";
        ".tmux.conf.local".source = ./tmux.conf.local;
      };
    };
}
