# workstation — Framework 13 Pro laptop (Intel Core Ultra 7 358H).
{ inputs, ... }:
{
  flake.nixosConfigurations.workstation = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; inherit (inputs) self; };
    modules = [
      inputs.disko.nixosModules.disko
      ../../disko/workstation.nix
      inputs.lanzaboote.nixosModules.lanzaboote
      ../../hosts/workstation
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
