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
  # VS Code Configuration
  # ============================================================================
  programs.vscode = {
    enable = true;

    # Let VS Code manage its own extensions (install Rose Pine via UI: mvllow.rose-pine)
    mutableExtensionsDir = true;

    userSettings = {
      # Font settings
      "editor.fontFamily" = "ComicCode Nerd Font";
      "editor.fontLigatures" = true;

      # Auto dark/light theme switching
      "window.autoDetectColorScheme" = true;
      "workbench.preferredDarkColorTheme" = "Rosé Pine Moon";
      "workbench.preferredLightColorTheme" = "Rosé Pine Dawn";
    };
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
