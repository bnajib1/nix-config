{ pkgs, username, ... }:

let
  commandUpArrow = "@" + builtins.fromJSON "\"\\uf700\"";
  commandDownArrow = "@" + builtins.fromJSON "\"\\uf701\"";
in

{
  # Let Determinate manage the Nix daemon and settings
  nix.enable = false;

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
        "/Applications/Slack.app"
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

    # Set time zone automatically from current location
    CustomSystemPreferences = {
      "com.apple.timezone.auto" = {
        Active = true;
      };
    };

    # Show seconds in menu bar clock
    menuExtraClock.ShowSeconds = true;

    # Trackpad: light click force
    trackpad = {
      FirstClickThreshold = 0;
      SecondClickThreshold = 0;
      ActuationStrength = 0;
    };

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
      "com.apple.tips" = {
        TPSAppAllowNotifications = false;
      };
      # Remove Downloads folder from dock (Trash stays — it's hardcoded by macOS)
      "com.apple.dock" = {
        persistent-others = [];
      };
    };
  };

  # Homebrew integration
  homebrew = {
    enable = true;
    taps = [
      "homebrew/core"
      "homebrew/cask"
    ];
    # Homebrew >= 6 refuses to load formulae from untrusted third-party taps,
    # and bundle cleanup resets the trust store to the Brewfile's `trusted:`
    # entries. nix-darwin's `taps` option cannot express `trusted:`, so the
    # hudochenkov tap is declared here instead of in `taps` above.
    extraConfig = ''
      tap "hudochenkov/sshpass", trusted: true
    '';
    onActivation = {
      # Taps are pinned flake inputs (read-only store links); `brew update`
      # cannot run against them. Version bumps come from `nix flake update`.
      autoUpdate = false;
      # Upgrade installed casks to the pinned tap versions on activation.
      upgrade = true;
      cleanup = "zap";
      # Homebrew >= 6 refuses non-interactive `bundle --cleanup` unless the
      # cleanup is forced; activation has no TTY.
      extraFlags = [ "--force-cleanup" ];
    };
    brews = [
      # Manually-installed CLI tools (install receipts: installed_on_request).
      # Their dependency closures are kept by `brew bundle cleanup` automatically.
      "llama.cpp"
      "node"
      "python@3.12"
      "tmux"
      "uv"
      # Orphaned library keg, declared to keep it (preserve-everything, Aug 2026).
      "fmt"
      # Robot workstation SSH (see ~/CLAUDE.md); tap is pinned as a flake input.
      "hudochenkov/sshpass/sshpass"
    ];
    # Keep manual `brew` invocations from attempting to update pinned taps.
    global.autoUpdate = false;
    casks = [
      "signal"
      "brave-browser"
      "ghostty"
      "slack"
      "visual-studio-code"
      "docker-desktop"
      "mactex"
      "iina"
      "qbittorrent"
      "protonvpn"
      "tailscale-app"
      "wispr-flow"
      # Installed manually (Jul 2026); declared so cleanup = "zap" keeps it.
      "moonlight"
    ];
  };

  # Install custom fonts to /Library/Fonts (system-wide, visible to Ghostty)
  system.activationScripts.postActivation.text = ''
    cp ${../fonts/ComicCodeNerdFont-Regular.otf} /Library/Fonts/ComicCodeNerdFont-Regular.otf 2>/dev/null || true

    # Block distracting sites via /etc/hosts
    for host in x.com www.x.com twitter.com www.twitter.com; do
      grep -qF "$host" /etc/hosts 2>/dev/null || printf '127.0.0.1 %s\n' "$host" >> /etc/hosts
    done

    # Strip quarantine flags from Homebrew-installed apps
    for app in /Applications/*.app; do
      xattr -d com.apple.quarantine "$app" 2>/dev/null || true
    done

    # Enable developer tools mode (suppresses TCC prompts for terminal apps)
    /usr/sbin/DevToolsSecurity -enable 2>/dev/null || true

    # Disable startup chime (Apple Silicon)
    /usr/sbin/nvram StartupMute=%01 2>/dev/null || true

    # Install Rosetta if not present
    if ! /usr/bin/pgrep -q oahd 2>/dev/null; then
      softwareupdate --install-rosetta --agree-to-license 2>/dev/null || true
    fi

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
      "force_installed"
    plist_set_string \
      "$BRAVE_POLICY_PLIST" \
      "ExtensionSettings:nngceckbapebfimnlniiiahkandclblb:update_url" \
      "https://extensionupdater.brave.com/service/update2/crx"
    plist_set_string \
      "$BRAVE_POLICY_PLIST" \
      "ExtensionSettings:nngceckbapebfimnlniiiahkandclblb:toolbar_pin" \
      "force_pinned"
    # Disable built-in password manager
    /usr/libexec/PlistBuddy -c "Delete :PasswordManagerEnabled" "$BRAVE_POLICY_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :PasswordManagerEnabled bool false" "$BRAVE_POLICY_PLIST"
    # Force Google as default search engine (normal + private)
    /usr/libexec/PlistBuddy -c "Delete :DefaultSearchProviderEnabled" "$BRAVE_POLICY_PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :DefaultSearchProviderEnabled bool true" "$BRAVE_POLICY_PLIST"
    plist_set_string "$BRAVE_POLICY_PLIST" "DefaultSearchProviderName" "Google"
    plist_set_string "$BRAVE_POLICY_PLIST" "DefaultSearchProviderSearchURL" "https://www.google.com/search?q={searchTerms}"
    plist_set_string "$BRAVE_POLICY_PLIST" "DefaultSearchProviderKeyword" "google.com"
    chmod 644 "$BRAVE_POLICY_PLIST"
    chown root:wheel "$BRAVE_POLICY_PLIST"
    /usr/bin/killall cfprefsd >/dev/null 2>&1 || true

    # Set Brave as default browser via Launch Services API directly
    # (defaultbrowser CLI can't see Brave until it's been opened once;
    # LSSetDefaultHandlerForURLScheme works immediately after lsregister)
    if [ -d "/Applications/Brave Browser.app" ]; then
      LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
      sudo -u ${username} "$LSREGISTER" -f "/Applications/Brave Browser.app" 2>/dev/null || true
      sudo -u ${username} /usr/bin/swift - <<'SETBROWSER' || warn "failed to set Brave as the default browser"
    import CoreServices
    import Foundation
    let bundleId = "com.brave.Browser" as CFString
    for scheme in ["http", "https"] {
      LSSetDefaultHandlerForURLScheme(scheme as CFString, bundleId)
    }
    SETBROWSER
    else
      warn "Brave Browser.app is not installed yet; skipping default browser assignment"
    fi

    CODE_APP=0
    if [ -d "/Applications/Visual Studio Code.app" ]; then
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
    import AppKit
    import CoreServices
    import Foundation
    import UniformTypeIdentifiers

    func warn(_ message: String) {
      FileHandle.standardError.write(Data(("warning: \(message)\n").utf8))
    }

    func setHandler(bundleId: String, uti: String) -> Bool {
      let status = LSSetDefaultRoleHandlerForContentType(
        uti as CFString, LSRolesMask.all, bundleId as CFString
      )
      return status == noErr
    }

    let env = ProcessInfo.processInfo.environment

    struct Mapping {
      let isInstalled: Bool
      let label: String
      let bundleId: String
      let utis: [String]
      let extensions: [String]
    }

    let videoUTIs = [
      "public.movie", "public.video", "public.avi",
      "public.mpeg", "public.mpeg-4", "com.apple.quicktime-movie",
      "public.3gpp", "public.3gpp2", "com.microsoft.windows-media-wmv"
    ]
    let videoExtensions = ["mkv", "flv", "wmv"]

    let mappings = [
      Mapping(
        isInstalled: env["CODE_APP"] == "1",
        label: "Visual Studio Code",
        bundleId: "com.microsoft.VSCode",
        utis: ["net.daringfireball.markdown", "public.comma-separated-values-text"],
        extensions: []
      ),
      Mapping(
        isInstalled: env["BRAVE_APP"] == "1",
        label: "Brave Browser",
        bundleId: "com.brave.Browser",
        utis: ["com.adobe.pdf"],
        extensions: []
      ),
      Mapping(
        isInstalled: env["IINA_APP"] == "1",
        label: "IINA",
        bundleId: "com.colliderli.iina",
        utis: videoUTIs,
        extensions: videoExtensions
      )
    ]

    for m in mappings {
      guard m.isInstalled else {
        warn("\(m.label) is not installed yet; skipping default handler assignment")
        continue
      }

      for uti in m.utis {
        if !setHandler(bundleId: m.bundleId, uti: uti) {
          warn("failed to set \(m.label) as handler for \(uti)")
        }
      }

      for ext in m.extensions {
        if let resolved = UTType(filenameExtension: ext) {
          if !setHandler(bundleId: m.bundleId, uti: resolved.identifier) {
            warn("failed to set \(m.label) as handler for .\(ext) (\(resolved.identifier))")
          }
        } else {
          warn("no UTI found for .\(ext); skipping")
        }
      }
    }
    SWIFT
  '';
}
