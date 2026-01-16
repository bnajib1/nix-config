{ pkgs, username, ... }:

{
  # Nix configuration
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Automatically optimize nix store
      auto-optimise-store = true;
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages available to all users
  environment.systemPackages = with pkgs; [
    git
  ];

  # Create /etc/zshrc that loads nix-darwin environment
  programs.zsh.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 5;

  # The platform the configuration is for
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set the primary user
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # macOS system preferences
  system.defaults = {
    # Dock settings
    dock = {
      autohide = true;
      show-recents = false;
    };

    # Finder settings
    finder = {
      AppleShowAllExtensions = true;
    };

    # Global settings
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      # Enable dark mode based on system preference
      AppleInterfaceStyleSwitchesAutomatically = true;
    };
  };

  # Homebrew integration (optional - for casks not in nixpkgs)
  # Uncomment if you want to manage Homebrew through nix-darwin
  # homebrew = {
  #   enable = true;
  #   onActivation = {
  #     autoUpdate = true;
  #     cleanup = "zap";
  #   };
  #   casks = [
  #     "ghostty"
  #     "visual-studio-code"
  #   ];
  # };
}
