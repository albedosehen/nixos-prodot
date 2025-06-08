{
  user,
  host,
  userConfig,
  lib,
  pkgs,
  ...
}: {
  wsl = lib.mkIf userConfig.capabilities.wsl {
    enable = true;
    defaultUser = user;

    docker-desktop.enable = true;

    interop = {
      includePath = true;
      register = true;
    };

    usbip = {
      enable = false;
      autoAttach = [];
    };

    useWindowsDriver = true;
    wrapBinSh = true;

    wslConf = {
      boot = {
        systemd = true;
        command = "echo 'NixOS 25.05 Ready'";
      };

      interop = {
        enabled = true;
        appendWindowsPath = true;
      };

      user.default = user;

      network = {
        hostname = host;
        generateHosts = true;
        generateResolvConf = true;
      };
    };

    startMenuLaunchers = true;
  };

  # https://nix.dev/guides/faq#how-to-run-non-nix-executables
  programs.nix-ld = {
    enable = true;
    package = pkgs.nix-ld-rs;
    libraries = with pkgs; [
      icu
      icu.dev
      stdenv.cc.cc.lib
      zlib
      openssl
      curl
      libxml2
      libxslt
    ];
  };
}
