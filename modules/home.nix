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
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ''
      font-family = ComicCode Nerd Font
      theme = light:Gruvbox Material Light,dark:Gruvbox Material Dark
      auto-update = check
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

    ${pkgs.gawk}/bin/awk '
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
          shows_options = 2;
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
  # Installed via Homebrew cask (not home-manager) to avoid symlink arrow in dock
  home.file."Library/Application Support/Code/User/settings.json" = {
    text = builtins.toJSON {
      "editor.fontFamily" = "ComicCode Nerd Font";
      "editor.fontLigatures" = true;
      "editor.minimap.enabled" = false;
      "editor.rulers" = [ 80 ];
      "editor.acceptSuggestionOnEnter" = "off";
      "window.autoDetectColorScheme" = true;
      "workbench.preferredDarkColorTheme" = "Gruvbox Material Dark";
      "workbench.preferredLightColorTheme" = "Gruvbox Material Light";
    };
  };

  home.activation.vscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
    if [ -x "$CODE" ]; then
      "$CODE" --install-extension sainnhe.gruvbox-material --force >/dev/null 2>&1 || true
      "$CODE" --install-extension James-Yu.latex-workshop --force >/dev/null 2>&1 || true
    fi
  '';

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
  # Written as a real file (not a symlink) so Claude Code can update it at runtime
  home.activation.claudeCodeConfig = let
    desired = builtins.toJSON {
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
  in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_DIR="$HOME/.claude"
    CLAUDE_SETTINGS="$CLAUDE_DIR/settings.json"
    mkdir -p "$CLAUDE_DIR"
    if [ -L "$CLAUDE_SETTINGS" ]; then
      rm "$CLAUDE_SETTINGS"
    fi
    if [ ! -f "$CLAUDE_SETTINGS" ]; then
      printf '%s\n' '${desired}' > "$CLAUDE_SETTINGS"
    else
      ${pkgs.jq}/bin/jq --argjson new '${desired}' '. * $new' "$CLAUDE_SETTINGS" > "$CLAUDE_SETTINGS.tmp" \
        && mv "$CLAUDE_SETTINGS.tmp" "$CLAUDE_SETTINGS"
    fi

    # Pre-accept workspace trust in the global config so the dialog doesn't
    # appear on every launch
    CLAUDE_GLOBAL="$HOME/.claude.json"
    if [ -f "$CLAUDE_GLOBAL" ]; then
      ${pkgs.jq}/bin/jq '
        .projects //= {} |
        .projects["/Users/'"$USER"'"] //= {} |
        .projects["/Users/'"$USER"'"].hasTrustDialogAccepted = true
      ' "$CLAUDE_GLOBAL" > "$CLAUDE_GLOBAL.tmp" \
        && mv "$CLAUDE_GLOBAL.tmp" "$CLAUDE_GLOBAL"
    fi
  '';

  # ============================================================================
  # Screenshot Shortcut (Cmd+Shift+W → copy screenshot of selected area)
  # ============================================================================
  # Symbolic hotkey ID 31 = "Copy picture of selected area to clipboard"
  # Parameters: [ASCII code, virtual key code, modifier flags]
  # W = ASCII 119, virtual key 13, Cmd+Shift = 1179648 (0x120000)
  home.activation.screenshotShortcut = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    PLIST="$HOME/Library/Preferences/com.apple.symbolichotkeys.plist"

    write_hotkey() {
      /usr/libexec/PlistBuddy "$PLIST" \
        -c "Delete :AppleSymbolicHotKeys:$1" \
        -c "Add :AppleSymbolicHotKeys:$1:enabled bool true" \
        -c "Add :AppleSymbolicHotKeys:$1:value:type string standard" \
        -c "Add :AppleSymbolicHotKeys:$1:value:parameters array" \
        -c "Add :AppleSymbolicHotKeys:$1:value:parameters:0 integer $2" \
        -c "Add :AppleSymbolicHotKeys:$1:value:parameters:1 integer $3" \
        -c "Add :AppleSymbolicHotKeys:$1:value:parameters:2 integer $4" \
        2>/dev/null || true
    }

    # 28 = save screen to file (Cmd+Shift+3)
    write_hotkey 28 51 20 1179648
    # 29 = copy screen to clipboard (Ctrl+Cmd+Shift+3)
    write_hotkey 29 51 20 1441792
    # 30 = save selected area to file (Cmd+Shift+4)
    write_hotkey 30 52 21 1179648
    # 31 = copy selected area to clipboard (remapped to Cmd+Shift+W)
    write_hotkey 31 119 13 1179648

    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u || true
  '';

  # ============================================================================
  # Dark Mode Toggle (Ctrl+Option+Cmd+T)
  # ============================================================================
  # Compiled native Swift binary — no third-party dependencies
  home.activation.darkModeToggle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.local/bin"
    SWIFT_SRC="$(mktemp /tmp/dark-mode-toggle.XXXXXX.swift)"
    cat > "$SWIFT_SRC" <<'SWIFT'
    import Cocoa
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if flags.contains([.control, .option, .command]) && event.keyCode == 17 {
            NSAppleScript(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode")?.executeAndReturnError(nil)
        }
    }
    app.run()
    SWIFT
    /usr/bin/swiftc -O -o "$HOME/.local/bin/dark-mode-toggle" -framework Cocoa "$SWIFT_SRC" 2>/dev/null || true
    rm -f "$SWIFT_SRC"
    launchctl bootout gui/$(id -u) "$HOME/Library/LaunchAgents/com.user.dark-mode-toggle.plist" 2>/dev/null || true
    launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/com.user.dark-mode-toggle.plist" 2>/dev/null || true
  '';

  launchd.agents.dark-mode-toggle = {
    enable = true;
    config = {
      ProgramArguments = [ "/Users/bnajib/.local/bin/dark-mode-toggle" ];
      KeepAlive = true;
      RunAtLoad = true;
      Label = "com.user.dark-mode-toggle";
    };
  };

  # ============================================================================
  # Codex Configuration
  # ============================================================================
  # Written as a real file (not a symlink) so Codex can write trust state at runtime
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CODEX_DIR="$HOME/.codex"
    CODEX_CONFIG="$CODEX_DIR/config.toml"
    mkdir -p "$CODEX_DIR"
    if [ -L "$CODEX_CONFIG" ]; then
      rm "$CODEX_CONFIG"
    fi
    cat > "$CODEX_CONFIG" <<'TOML'
approval_policy = "never"
sandbox_mode = "danger-full-access"

[history]
persistence = "save-all"
TOML
  '';
}
