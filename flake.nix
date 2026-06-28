{
  description = "NixOS configuration for lansidev's machines (battlestation desktop, workstation laptop)";

  inputs = {
    # Hydra-tested stable channel. Bump to the next nixos-YY.MM branch when
    # cutting a release upgrade; revisit per-package `nixpkgs-unstable` pulls
    # at the same time since the stable lag is usually the reason they exist.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Bleeding-edge channel used only for fast-moving packages where the
    # current stable release lags too far behind upstream. Pull from this
    # sparingly and explicitly per package.
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake outputs are produced by evaluating Nixpkgs-style modules instead
    # of one hand-written attrset — definitions of the same option merge
    # across files, which is what the dendritic layout under `modules/`
    # relies on.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Auto-imports every .nix file under a directory (ignoring `_`-prefixed
    # paths) so module files never have to be listed by hand.
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Canned hardware modules — used by `workstation` for the
    # Framework 13 Pro / Intel Core Ultra series 3 (Panther Lake) defaults
    # (fwupd, fingerprint, kmod tweaks). nixos-hardware does not take
    # nixpkgs as an input, so no `inputs.nixpkgs.follows` here.
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Marketplace mirror for VSCode extensions — gives access to every
    # extension on the Visual Studio Marketplace and Open VSX, not just
    # the ~200 curated ones in nixpkgs `vscode-extensions`.
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pre-commit framework: provides the devShell `shellHook` that installs
    # `.git/hooks/pre-commit`. Runs `gitleaks` on staged content so secrets
    # can't land in the public history by accident.
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Quickshell-based Wayland shell that replaces waybar. Upstream requires
    # nixpkgs unstable for the Quickshell version it depends on, so we point
    # the input at our unstable channel rather than the stable one.
    #
    # Pinned to an explicit v5 (main) commit rather than a floating branch ref:
    # v5 is still alpha and `rebuild()` runs `nix flake update` on every switch
    # (see modules/shell/zsh.nix), so a bare ref would silently float to newer
    # alpha commits each rebuild. Bump deliberately by editing the rev here.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell/7421f80b041e81d6e202a25ade6bfc59d716dd43";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    # Standalone wlroots login greeter for greetd that matches Noctalia's look,
    # used in place of ReGreet (see modules/desktop/greeter.nix). Unlike ReGreet
    # — a GTK4 app hosted inside `cage` — this ships its own wlroots compositor
    # (`noctalia-greeter-compositor`) and binds greetd itself, so it replaces the
    # cage+regreet path wholesale. It is independent of the noctalia-shell input
    # above (no Quickshell), so it follows our stable `nixpkgs`, which already
    # carries the wlroots_0_20 it builds against.
    #
    # Pinned to an explicit commit for the same reason as `noctalia`: `rebuild()`
    # runs `nix flake update` on every switch (see modules/shell/zsh.nix), so a
    # floating ref would drift each rebuild. Bump deliberately by editing the rev.
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter/c09a6b5067ab104d6a47fa404ab4ef1f423c3f4c";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Encrypted-at-rest secrets. age-encrypted YAML in `secrets/`, decrypted
    # at activation time into `/run/secrets/...` using the system's SSH host
    # key. sops-nix doesn't maintain release-* branches; master targets
    # current-stable nixpkgs and `flake.lock` pins a specific commit.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
