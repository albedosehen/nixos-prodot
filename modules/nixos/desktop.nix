{
  userConfig,
  pkgs,
  lib,
  ...
}: {
  # Desktop Environment Configuration
  services.xserver = lib.mkMerge [
    (lib.mkIf userConfig.capabilities.desktop {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    })
    (lib.mkIf userConfig.capabilities.nvidia {
      videoDrivers = ["nvidia"];
    })
  ];

  # Audio Configuration
  hardware.pulseaudio = lib.mkIf userConfig.capabilities.desktop {
    enable = false; # Use pipewire instead
  };

  security.rtkit.enable = lib.mkIf userConfig.capabilities.desktop true;
  services.pipewire = lib.mkIf userConfig.capabilities.desktop {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth Configuration
  hardware.bluetooth = lib.mkIf userConfig.capabilities.desktop {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = lib.mkIf userConfig.capabilities.desktop true;

  # NVIDIA Graphics Configuration
  hardware.nvidia = lib.mkIf userConfig.capabilities.nvidia {
    modesetting.enable = true;
    powerManagement.enable = lib.mkIf userConfig.capabilities.power true;
    powerManagement.finegrained = lib.mkIf userConfig.capabilities.power true;
    open = false; # Use proprietary driver
    nvidiaSettings = true;
    package = lib.mkDefault pkgs.linuxPackages.nvidiaPackages.stable;
  };

  # OpenGL Configuration for GPU acceleration
  hardware.graphics = lib.mkIf (userConfig.capabilities.nvidia || userConfig.capabilities.desktop) {
    enable = true;
    enable32Bit = true;
  };

  # Docker Configuration
  virtualisation.docker = lib.mkIf userConfig.capabilities.docker {
    enable = true;
    enableOnBoot = true;
  };

  # Additional desktop packages
  environment.systemPackages = lib.mkIf userConfig.capabilities.desktop (with pkgs; [
    firefox
    gnome-tweaks
    dconf-editor
    gnome-extension-manager
  ]);
}
