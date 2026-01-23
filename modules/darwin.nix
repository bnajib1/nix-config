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
      # Disable bottom-right hot corner (Quick Note/Sticky Notes)
      wvous-br-corner = 1;
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

    # Disable Siri
    CustomUserPreferences = {
      "com.apple.assistant.support" = {
        "Assistant Enabled" = false;
      };
      "com.apple.Siri" = {
        StatusMenuVisible = false;
        UserHasDeclinedEnable = true;
      };
      "com.apple.Spotlight" = {
        MenuItemHidden = true;
      };
    };
  };

  # Homebrew integration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    brews = [
      "defaultbrowser"
    ];
    casks = [
      "signal"
      "brave-browser"
      "claude"
      "mactex"
      "iina"
      "qbittorrent"
    ];
  };

  # Set Brave as default browser (will prompt for confirmation on first run)
  system.activationScripts.postActivation.text = ''
    if command -v defaultbrowser &> /dev/null; then
      defaultbrowser brave || true
    fi
  '';
}
