{
  description = "Configuration NixOS de maousse";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
  };
};
  outputs = { self, nixpkgs, home-manager, plasma-manager }: {
    nixosConfigurations.maousse = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.sinsry = {

            imports = [ plasma-manager.homeModules.plasma-manager ];
            programs.plasma = {
              enable = true;
              workspace.numlock = "on";
              };
            };
          }
        ];
     };
   };
}
