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

    userSettings = {
      # Font settings
      "editor.fontFamily" = "ComicCode Nerd Font";
      "editor.fontLigatures" = true;

      # Auto dark/light theme switching
      "window.autoDetectColorScheme" = true;
      "workbench.preferredDarkColorTheme" = "Rosé Pine Moon";
      "workbench.preferredLightColorTheme" = "Rosé Pine Dawn";
    };

    # Extensions
    # Note: The Rose Pine theme extension needs to be installed
    # You can add it via the marketplace ID or find it in nixpkgs
    extensions = with pkgs.vscode-extensions; [
      # Add extensions from nixpkgs here
      # Example: ms-python.python
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      # Rose Pine theme from VS Code marketplace
      {
        name = "rose-pine";
        publisher = "mvllow";
        version = "2.9.0";
        # To get the sha256, run:
        # nix-prefetch-url --type sha256 "https://mvllow.gallery.vsassets.io/_apis/public/gallery/publisher/mvllow/extension/rose-pine/2.9.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
        # Then convert to base64: nix hash to-sri --type sha256 <hash>
        sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
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
