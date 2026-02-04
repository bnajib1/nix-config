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
      tilesize = 52;
      persistent-apps = [
        "/Applications/Brave Browser.app"
        "/System/Applications/Calendar.app"
        "/System/Applications/Notes.app"
        "/Applications/Signal.app"
        "/Applications/Visual Studio Code.app"
        "/Applications/Ghostty.app"
        "/System/Applications/System Settings.app"
      ];
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
      # IINA: Quit when last window closes
      "com.colliderli.iina" = {
        quitWhenNoOpenedWindow = true;
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
      "protonvpn"
    ];
  };

  # Set default applications for file types
  system.activationScripts.postActivation.text = ''
    if command -v defaultbrowser &> /dev/null; then
      defaultbrowser brave || true
    fi
    # Set default apps using native Launch Services API
    swift - <<'SWIFT' 2>/dev/null || true
    import Foundation
    import CoreServices

    // Brave for PDF
    LSSetDefaultRoleHandlerForContentType("com.adobe.pdf" as CFString, .all, "com.brave.Browser" as CFString)

    // IINA for video formats
    let videoTypes = [
      "public.movie",
      "public.video",
      "public.avi",
      "public.mpeg",
      "public.mpeg-4",
      "com.apple.quicktime-movie",
      "public.3gpp",
      "public.3gpp2",
      "org.matroska.mkv",
      "com.microsoft.windows-media-wmv"
    ]
    for type in videoTypes {
      LSSetDefaultRoleHandlerForContentType(type as CFString, .all, "com.colliderli.iina" as CFString)
    }
    SWIFT
  '';
}
