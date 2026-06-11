# battlestation — desktop (AMD Ryzen 7 9800X3D, RX 9070 XT, ultrawide).
{ inputs, ... }:
{
  flake.nixosConfigurations.battlestation = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; inherit (inputs) self; };
    modules = [
      inputs.disko.nixosModules.disko
      ../../disko/battlestation.nix
      inputs.lanzaboote.nixosModules.lanzaboote
      ../../hosts/battlestation
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs; };
        home-manager.users.lansing = import ../../home/lansing;
      }
    ];
  };
}
