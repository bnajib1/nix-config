{ config, pkgs, lib, ... }:

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
  # Ghostty Configuration
  # ============================================================================
  # Config location: ~/Library/Application Support/com.mitchellh.ghostty/config
  home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
    text = ''
      font-family = ComicCode Nerd Font
      theme = light:Rose Pine Dawn,dark:Rose Pine Moon
    '';
  };

  # ============================================================================
  # Claude Code Configuration
  # ============================================================================
  home.file.".claude/settings.json" = {
    text = builtins.toJSON {
      includeCoAuthoredBy = false;
      model = "claude-opus-4-5-20251101";
    };
  };

  # ============================================================================
  # qBittorrent Configuration
  # ============================================================================
  home.file."Library/Preferences/qBittorrent/qBittorrent.ini" = {
    text = ''
      [BitTorrent]
      Session\MaxRatio=0
      Session\MaxRatioAction=0
    '';
  };

  # ============================================================================
  # Brave Browser Configuration
  # ============================================================================
  # Merges settings into Brave's Preferences on activation.
  # Close Brave before running `darwin-rebuild switch` for settings to apply.
  # Bitwarden must be installed from Chrome Web Store on first setup:
  # https://chromewebstore.google.com/detail/bitwarden/nngceckbapebfimnlniiiahkandclblb
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

    if [ -f "$BRAVE_PREFS" ]; then
      ${pkgs.jq}/bin/jq --argjson new '${bravePrefs}' '. * $new' "$BRAVE_PREFS" > "$BRAVE_PREFS.tmp" \
        && mv "$BRAVE_PREFS.tmp" "$BRAVE_PREFS"
    fi

    if [ -f "$BRAVE_LOCAL" ]; then
      ${pkgs.jq}/bin/jq --argjson new '${braveLocalState}' '. * $new' "$BRAVE_LOCAL" > "$BRAVE_LOCAL.tmp" \
        && mv "$BRAVE_LOCAL.tmp" "$BRAVE_LOCAL"
    fi
  '';

  # ============================================================================
  # VS Code Configuration
  # ============================================================================
  programs.vscode = {
    enable = true;

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
      "workbench.preferredDarkColorTheme" = "Rosé Pine Moon";
      "workbench.preferredLightColorTheme" = "Rosé Pine Dawn";
    };

    extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "rose-pine";
        publisher = "mvllow";
        version = "2.9.0";
        sha256 = "sha256-ibx19iDUXumpc1vTIUubceFyWyD7nUEBlunFDMcdW6E=";
      }
      {
        name = "claude-code";
        publisher = "anthropic";
        version = "2.1.9";
        sha256 = "sha256-aFEBGY3QWSmPK6709juFStmdZzzmEXoC2Kzljs/bG+U=";
      }
      {
        name = "latex-workshop";
        publisher = "James-Yu";
        version = "10.9.1";
        sha256 = "sha256-R+tJ3k71rlzfxtz4Dib6JiU7Sipq/UTP38ERAhojY7c=";
      }
    ];
  };

  # ============================================================================
  # Additional Packages (optional)
  # ============================================================================
  home.packages = with pkgs; [
    # Add any additional packages you want installed
    # ripgrep
    # fd
    # bat
  ];
}
