{
  description = "Nix-darwin configuration with home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager }:
  let
    # Change this to your desired username
    username = "bnajib";
  in
  {
    darwinConfigurations = {
      mbp = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin"; # Use "x86_64-darwin" for Intel Macs
        modules = [
          ./modules/darwin.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./modules/home.nix;

            # Pass extra arguments to home.nix
            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
          }
        ];
        specialArgs = { inherit inputs username; };
      };
    };

    # Expose the package set for convenience
    darwinPackages = self.darwinConfigurations.mbp.pkgs;
  };
}
