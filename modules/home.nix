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
