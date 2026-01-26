{
  description = "Configuration NixOS travail";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
};

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.travail = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}
