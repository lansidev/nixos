# Declarative disk layouts. The per-host layout file stays under disko/
# (outside the import-tree — it is a plain NixOS module that disko-install
# also consumes by path) and is imported by modules/hosts/<name>.nix.
{ inputs, ... }:
{
  flake.modules.nixos.base.imports = [ inputs.disko.nixosModules.disko ];
}
