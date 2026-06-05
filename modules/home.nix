{ config, pkgs, lib, ... }:

let
  wallpaperTarget = "Pictures/Wallpapers/paisagem-branca.jpg";
  applyWallpaper = pkgs.writeShellScript "apply-wallpaper" ''
    set -eu

    WALLPAPER="$HOME/${wallpaperTarget}"

    if [ ! -f "$WALLPAPER" ]; then
      printf 'warning: wallpaper is unavailable at %s\n' "$WALLPAPER" >&2
      exit 0
    fi

    export CLANG_MODULE_CACHE_PATH=/tmp/nix-config-clang-module-cache
    mkdir -p "$CLANG_MODULE_CACHE_PATH"

    /usr/bin/swift - "$WALLPAPER" <<'SWIFT'
    import AppKit
    import Darwin
    import Foundation

    func warn(_ message: String) {
      FileHandle.standardError.write(Data(("warning: \(message)\n").utf8))
    }

    guard CommandLine.arguments.count > 1 else {
      warn("missing wallpaper path")
      exit(1)
    }

    let wallpaperURL = URL(fileURLWithPath: CommandLine.arguments[1])
    guard FileManager.default.fileExists(atPath: wallpaperURL.path) else {
      warn("wallpaper does not exist at \(wallpaperURL.path)")
      exit(0)
    }

    let fillColor = NSColor(
      calibratedRed: 0.2549019608,
      green: 0.4117647059,
      blue: 0.6666666667,
      alpha: 1.0
    )
    let options: [NSWorkspace.DesktopImageOptionKey: Any] = [
      .imageScaling: NSNumber(value: NSImageScaling.scaleProportionallyUpOrDown.rawValue),
      .allowClipping: NSNumber(value: true),
      .fillColor: fillColor
    ]

    let screens = NSScreen.screens
    if screens.isEmpty {
      warn("no active screens are available for wallpaper assignment")
      exit(0)
    }

    var failures = 0
    for screen in screens {
      do {
        try NSWorkspace.shared.setDesktopImageURL(wallpaperURL, for: screen, options: options)
      } catch {
        failures += 1
        warn("failed to set wallpaper for \(screen.localizedName): \(error)")
      }
    }

    if failures > 0 {
      exit(1)
    }
    SWIFT
  '';
in

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.stateVersion = "24.05";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # ============================================================================
  # Font Installation
  # ============================================================================
  # Install the Comic Code Nerd Font to ~/Library/Fonts/
  home.file."Library/Fonts/ComicCodeNerdFont-Regular.otf" = {
    source = ../fonts/ComicCodeNerdFont-Regular.otf;
  };

  # ============================================================================
  # Wallpaper
  # ============================================================================
  # Current macOS placement: Crop, with the stored fill color preserved.
  home.file.${wallpaperTarget} = {
    source = ../wallpapers/paisagem-branca.jpg;
  };

  launchd.agents.apply-wallpaper = {
    enable = true;
    config = {
      ProgramArguments = [ "${applyWallpaper}" ];
      RunAtLoad = true;
    };
  };

  home.activation.applyWallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${applyWallpaper} || printf 'warning: failed to set wallpaper\n' >&2
  '';

  # ============================================================================
  # Ghostty Configuration
  # ============================================================================
  # Config location: ~/Library/Application Support/com.mitchellh.ghostty/config
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ''
      font-family = ComicCode Nerd Font
      theme = Nord
    '';
  };

  # ============================================================================
  # qBittorrent Configuration
  # ============================================================================
  # qBittorrent rewrites this file at runtime, so merge the desired keys instead
  # of making the INI immutable with home.file.
  home.activation.qbittorrentConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    QBITTORRENT_DIR="$HOME/Library/Preferences/qBittorrent"
    QBITTORRENT_INI="$QBITTORRENT_DIR/qBittorrent.ini"
    TMP_FILE="$(mktemp)"

    mkdir -p "$QBITTORRENT_DIR"
    touch "$QBITTORRENT_INI"

    awk '
      BEGIN {
        in_section = 0
        saw_section = 0
        saw_max_ratio = 0
        saw_ratio_action = 0
      }

      /^\[BitTorrent\]$/ {
        saw_section = 1
        in_section = 1
        print
        next
      }

      /^\[/ {
        if (in_section) {
          if (!saw_max_ratio) {
            print "Session\\MaxRatio=0"
          }
          if (!saw_ratio_action) {
            print "Session\\MaxRatioAction=0"
          }
          in_section = 0
        }
        print
        next
      }

      in_section && /^Session[\\]+MaxRatio=/ {
        print "Session\\MaxRatio=0"
        saw_max_ratio = 1
        next
      }

      in_section && /^Session[\\]+MaxRatioAction=/ {
        print "Session\\MaxRatioAction=0"
        saw_ratio_action = 1
        next
      }

      {
        print
      }

      END {
        if (!saw_section) {
          if (NR > 0) {
            print ""
          }
          print "[BitTorrent]"
          print "Session\\MaxRatio=0"
          print "Session\\MaxRatioAction=0"
        } else if (in_section) {
          if (!saw_max_ratio) {
            print "Session\\MaxRatio=0"
          }
          if (!saw_ratio_action) {
            print "Session\\MaxRatioAction=0"
          }
        }
      }
    ' "$QBITTORRENT_INI" > "$TMP_FILE" && mv "$TMP_FILE" "$QBITTORRENT_INI"
  '';

  # ============================================================================
  # Brave Browser Configuration
  # ============================================================================
  # Merges settings into Brave's Preferences on activation.
  # Close Brave before running `darwin-rebuild switch` for settings to apply.
  # Bitwarden is installed by a managed Brave policy in modules/darwin.nix.
  home.activation.braveConfig = let
    bravePrefs = builtins.toJSON {
      brave = {
        # Vertical tabs with card preview on hover
        tabs = {
          vertical_tabs_enabled = true;
          hover_mode = 2;
        };
        # Wide URL bar
        location_bar_is_wide = true;
        # Hide side panel button
        show_side_panel_button = false;
        # Hide bookmark bar on new tab page
        always_show_bookmark_bar_on_ntp = false;
        # Confirm before closing window with multiple tabs
        enable_window_closing_confirm = true;
        # Disable Leo AI
        ai_chat = {
          show_toolbar_button = false;
          autocomplete_provider_enabled = false;
        };
        # Hide VPN button
        brave_vpn = {
          show_button = false;
        };
        # Hide crypto wallet icon
        wallet = {
          show_wallet_icon_on_toolbar = false;
        };
        # Hide rewards button
        rewards = {
          show_brave_rewards_button_in_location_bar = false;
        };
        # Clean new tab page
        new_tab_page = {
          show_brave_news = false;
          show_rewards = false;
          show_brave_vpn = false;
          show_together = false;
        };
        # Disable omnibox bookmark and commander suggestions
        omnibox = {
          bookmark_suggestions_enabled = false;
          commander_suggestions_enabled = false;
        };
      };
      # Pin Bitwarden extension to toolbar
      extensions = {
        pinned_extensions = [ "nngceckbapebfimnlniiiahkandclblb" ];
      };
      # Hide tab search button from toolbar
      toolbar = {
        pinned_actions = [ "kActionShowChromeLabs" ];
      };
    };
    braveLocalState = builtins.toJSON {
      brave = {
        # Enable Widevine DRM support (Netflix, etc.)
        widevine_opted_in = true;
      };
    };
  in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    BRAVE_DIR="$HOME/Library/Application Support/BraveSoftware/Brave-Browser"
    BRAVE_PREFS="$BRAVE_DIR/Default/Preferences"
    BRAVE_LOCAL="$BRAVE_DIR/Local State"

    ensure_json_file() {
      local target="$1"
      local label="$2"
      local backup="$target.pre-nix-config.bak"

      mkdir -p "$(dirname "$target")"

      if [ ! -f "$target" ]; then
        printf '{}\n' > "$target"
        return
      fi

      if ! ${pkgs.jq}/bin/jq empty "$target" >/dev/null 2>&1; then
        cp "$target" "$backup"
        printf '{}\n' > "$target"
        printf 'warning: reset invalid %s JSON and backed it up to %s\n' "$label" "$backup" >&2
      fi
    }

    mkdir -p "$BRAVE_DIR/Default"
    ensure_json_file "$BRAVE_PREFS" "Brave Preferences"
    ensure_json_file "$BRAVE_LOCAL" "Brave Local State"

    ${pkgs.jq}/bin/jq --argjson new '${bravePrefs}' '. * $new' "$BRAVE_PREFS" > "$BRAVE_PREFS.tmp" \
      && mv "$BRAVE_PREFS.tmp" "$BRAVE_PREFS"

    ${pkgs.jq}/bin/jq --argjson new '${braveLocalState}' '. * $new' "$BRAVE_LOCAL" > "$BRAVE_LOCAL.tmp" \
      && mv "$BRAVE_LOCAL.tmp" "$BRAVE_LOCAL"
  '';

  # ============================================================================
  # VS Code Configuration
  # ============================================================================
  programs.vscode = {
    enable = true;

    profiles.default = {
      userSettings = {
        # Font settings
        "editor.fontFamily" = "ComicCode Nerd Font";
        "editor.fontLigatures" = true;

        # Editor settings
        "editor.minimap.enabled" = false;
        "editor.rulers" = [ 80 ];
        "editor.acceptSuggestionOnEnter" = "off";

        # Auto dark/light theme switching
        "window.autoDetectColorScheme" = true;
        "workbench.preferredDarkColorTheme" = "Nord";
        "workbench.preferredLightColorTheme" = "Nord";
      };

      extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "nord-visual-studio-code";
          publisher = "arcticicestudio";
          version = "0.19.0";
          sha256 = "sha256-awbqFv6YuYI0tzM/QbHRTUl4B2vNUdy52F4nPmv+dRU=";
        }
        {
          name = "latex-workshop";
          publisher = "James-Yu";
          version = "10.9.1";
          sha256 = "sha256-R+tJ3k71rlzfxtz4Dib6JiU7Sipq/UTP38ERAhojY7c=";
        }
      ];
    };
  };

  # ============================================================================
  # Git Configuration
  # ============================================================================
  programs.git = {
    enable = true;
    signing.format = null;
    settings.user = {
      name = "Benjamin Najib";
      email = "202577703+bnajib1@users.noreply.github.com";
    };
  };

  # ============================================================================
  # Additional Packages (optional)
  # ============================================================================
  home.packages = with pkgs; [
    claude-code
    codex
    gh
    (mactop.overrideAttrs { doCheck = false; })
  ];

  # ============================================================================
  # Claude Code Configuration
  # ============================================================================
  home.file.".claude/settings.json" = {
    text = builtins.toJSON {
      theme = "auto";
      model = "claude-opus-4-6";
      effortLevel = "max";
      cleanupPeriodDays = 36500;
      attribution = {
        commit = "";
        pr = "";
      };
      permissions = {
        allow = [
          "Bash(*)"
          "Edit(*)"
          "Write(*)"
          "Read(*)"
          "WebFetch(*)"
          "WebSearch(*)"
          "NotebookEdit(*)"
        ];
      };
    };
  };

  # ============================================================================
  # Codex Configuration
  # ============================================================================
  home.file.".codex/config.toml" = {
    text = ''
      approval_policy = "never"
      sandbox_mode = "danger-full-access"

      [history]
      persistence = "save-all"
    '';
  };
}
