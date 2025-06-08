{
  pkgs,
  userConfig,
  lib,
  ...
}: let
  scripts = import ./scripts {inherit pkgs;};
in {
  environment = {
    systemPackages = with pkgs; [
      git
      curl
      wget
      vim
      htop
      tree
      file
      unzip
      which
      gnugrep
      gnused
      gawk
      coreutils
      nh
      icu
      icu.dev
      scripts.switch-profile
    ];

    variables = {
      EDITOR = "nvim";
      BROWSER = lib.mkIf userConfig.capabilities.wsl "wslview";
      # Ensure ICU libraries are discoverable for interop scenarios
      ICU_DATA = "${pkgs.icu}/share/icu";
      LD_LIBRARY_PATH = lib.mkAfter "${pkgs.icu}/lib";
    };

    shells = [pkgs.zsh];
  };

  programs = {
    zsh.enable = true;
    git.enable = true;

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    command-not-found.enable = false;
  };

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.symbols-only
    ];
  };

  time.timeZone = "America/Anchorage";
  i18n.defaultLocale = "en_US.UTF-8";

  services = {
    openssh = {
      enable = false;
    };

    dbus.enable = true;
  };
}
