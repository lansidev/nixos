{
  flake.modules.homeManager.base = { config, ... }: {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;

      # Auto-trust the home-manager-managed ~/.envrc so each rebuild that
      # rotates its /nix/store target doesn't require a fresh `direnv allow`.
      # Nested .envrc files still need to be allowed explicitly.
      config.whitelist.exact = [ "${config.home.homeDirectory}/.envrc" ];
    };
  };
}
