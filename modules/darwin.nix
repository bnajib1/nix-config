{ pkgs, username, ... }:

let
  commandUpArrow = "@" + builtins.fromJSON "\"\\uf700\"";
  commandDownArrow = "@" + builtins.fromJSON "\"\\uf701\"";
in

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

  # Hostname
  networking.hostName = "mbp";
  networking.computerName = "mbp";
  networking.localHostName = "mbp";

  # Create /etc/zshrc that loads nix-darwin environment
  programs.zsh.enable = true;

  # Used for backwards compatibility
  system.stateVersion = 5;

  # The platform the configuration is for
  nixpkgs.hostPlatform = "aarch64-darwin";

  # Set the primary user
  system.primaryUser = username;
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
        "/Users/${username}/Applications/Home Manager Apps/Visual Studio Code.app"
        "/Applications/Ghostty.app"
        "/System/Applications/System Settings.app"
      ];
      # Disable bottom-right hot corner (Quick Note/Sticky Notes)
      wvous-br-corner = 1;
    };

    # Window Manager / Stage Manager settings
    WindowManager = {
      StandardHideDesktopIcons = true;       # Disable "Show items on desktop"
      StandardHideWidgets = true;             # Disable "Show widgets on desktop"
      HideDesktop = true;                    # Disable "Show items in Stage Manager"
      EnableStandardClickToShowDesktop = false; # "Click wallpaper to show desktop" = Only in Stage Manager
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
      # Mute alert beeps and volume-key feedback sounds.
      "com.apple.sound.beep.volume" = 0.0;
      "com.apple.sound.beep.feedback" = 0;
    };

    # Keep Tahoe Liquid Glass transparency enabled.
    universalaccess.reduceTransparency = false;

    # Disable Siri
    CustomUserPreferences = {
      "NSGlobalDomain" = {
        # Keep Tahoe's Liquid Glass renderer enabled and allow wallpaper tinting.
        "com.apple.SwiftUI.DisableSolarium" = false;
        AppleReduceDesktopTinting = false;
        NSAutomaticEmojiSubstitutionEnabled = false;
      };
      "com.apple.Accessibility" = {
        # Keep Liquid Glass contrast at the normal system appearance.
        DarkenSystemColors = false;
        EnhancedBackgroundContrastEnabled = false;
      };
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
      "com.brave.Browser" = {
        NSUserKeyEquivalents = {
          "Select Previous Tab" = commandUpArrow;
          "Select Next Tab" = commandDownArrow;
        };
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
      "ghostty"
      "mactex"
      "iina"
      "qbittorrent"
      "protonvpn"
    ];
  };

  # Set default applications for file types
  system.activationScripts.postActivation.text = ''
    warn() {
      printf 'warning: %s\n' "$1" >&2
    }

    BRAVE_POLICY_PLIST="/Library/Managed Preferences/com.brave.Browser.plist"

    plist_ensure_dict() {
      /usr/libexec/PlistBuddy -c "Add :$2 dict" "$1" 2>/dev/null || true
    }

    plist_set_string() {
      /usr/libexec/PlistBuddy -c "Set :$2 $3" "$1" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "Add :$2 string $3" "$1"
    }

    mkdir -p "/Library/Managed Preferences"
    if [ ! -f "$BRAVE_POLICY_PLIST" ]; then
      /usr/bin/plutil -create xml1 "$BRAVE_POLICY_PLIST"
    fi
    plist_ensure_dict "$BRAVE_POLICY_PLIST" "ExtensionSettings"
    plist_ensure_dict "$BRAVE_POLICY_PLIST" "ExtensionSettings:nngceckbapebfimnlniiiahkandclblb"
    plist_set_string \
      "$BRAVE_POLICY_PLIST" \
      "ExtensionSettings:nngceckbapebfimnlniiiahkandclblb:installation_mode" \
      "normal_installed"
    plist_set_string \
      "$BRAVE_POLICY_PLIST" \
      "ExtensionSettings:nngceckbapebfimnlniiiahkandclblb:update_url" \
      "https://clients2.google.com/service/update2/crx"
    chmod 644 "$BRAVE_POLICY_PLIST"
    chown root:wheel "$BRAVE_POLICY_PLIST"
    /usr/bin/killall cfprefsd >/dev/null 2>&1 || true

    if command -v defaultbrowser >/dev/null 2>&1; then
      if [ -d "/Applications/Brave Browser.app" ]; then
        defaultbrowser brave || warn "failed to set Brave as the default browser"
      else
        warn "Brave Browser.app is not installed yet; skipping default browser assignment"
      fi
    else
      warn "defaultbrowser is unavailable; skipping default browser assignment"
    fi

    CODE_APP=0
    if [ -d "/Applications/Visual Studio Code.app" ] \
      || [ -d "/Users/${username}/Applications/Home Manager Apps/Visual Studio Code.app" ]; then
      CODE_APP=1
    fi
    BRAVE_APP=0
    if [ -d "/Applications/Brave Browser.app" ]; then
      BRAVE_APP=1
    fi
    IINA_APP=0
    if [ -d "/Applications/IINA.app" ]; then
      IINA_APP=1
    fi

    # Set default apps using native Launch Services API
    CODE_APP="$CODE_APP" BRAVE_APP="$BRAVE_APP" IINA_APP="$IINA_APP" /usr/bin/swift - <<'SWIFT' \
      || warn "failed to update default app handlers"
    import Foundation
    import CoreServices

    struct Mapping {
      let isInstalled: Bool
      let label: String
      let bundleIdentifier: String
      let contentTypes: [String]
    }

    func warn(_ message: String) {
      FileHandle.standardError.write(Data(("warning: \(message)\n").utf8))
    }

    let environment = ProcessInfo.processInfo.environment

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

    let mappings = [
      Mapping(
        isInstalled: environment["CODE_APP"] == "1",
        label: "Visual Studio Code",
        bundleIdentifier: "com.microsoft.VSCode",
        contentTypes: [
          "net.daringfireball.markdown",
          "public.comma-separated-values-text"
        ]
      ),
      Mapping(
        isInstalled: environment["BRAVE_APP"] == "1",
        label: "Brave Browser",
        bundleIdentifier: "com.brave.Browser",
        contentTypes: [ "com.adobe.pdf" ]
      ),
      Mapping(
        isInstalled: environment["IINA_APP"] == "1",
        label: "IINA",
        bundleIdentifier: "com.colliderli.iina",
        contentTypes: videoTypes
      )
    ]

    for mapping in mappings {
      guard mapping.isInstalled else {
        warn("\(mapping.label) is not installed yet; skipping default handler assignment")
        continue
      }

      for contentType in mapping.contentTypes {
        let status = LSSetDefaultRoleHandlerForContentType(
          contentType as CFString,
          LSRolesMask.all,
          mapping.bundleIdentifier as CFString
        )
        if status != noErr {
          warn(
            "failed to set \(mapping.label) as the default handler for \(contentType) " +
            "(OSStatus \(status))"
          )
        }
      }
    }
    SWIFT
  '';
}
