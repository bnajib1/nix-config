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

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };

    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

    homebrew-sshpass = {
      url = "github:hudochenkov/homebrew-sshpass";
      flake = false;
    };
  };

  outputs = inputs@{
    self,
    nixpkgs,
    nix-darwin,
    home-manager,
    nix-homebrew,
    homebrew-core,
    homebrew-cask,
    homebrew-sshpass,
  }:
  let
    username = "bnajib";
  in
  {
    darwinConfigurations = {
      mbp = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./modules/darwin.nix

          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "bak";
            home-manager.users.${username} = import ./modules/home.nix;

            home-manager.extraSpecialArgs = {
              inherit inputs;
            };
          }

          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
              # nix-homebrew exports HOMEBREW_NO_INSTALL_FROM_API=1 itself
              # whenever homebrew/homebrew-core is a declared tap.
              taps = {
                "homebrew/homebrew-core" = inputs.homebrew-core;
                "homebrew/homebrew-cask" = inputs.homebrew-cask;
                "hudochenkov/homebrew-sshpass" = inputs.homebrew-sshpass;
              };
              # Homebrew >= 6 tap-trust: trust the third-party tap during
              # activation, before `brew bundle` needs to load its formula.
              trust.taps = [ "hudochenkov/sshpass" ];
            };
          }
        ];
        specialArgs = { inherit inputs username; };
      };
    };

    darwinPackages = self.darwinConfigurations.mbp.pkgs;
  };
}
