{
  flake.modules.nixos.base = {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };
    # Auth key bootstrap: `nix run .#tailscale-up`
    # (defined in modules/meta/bootstrap-apps.nix).
  };
}
