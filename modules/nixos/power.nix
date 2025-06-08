{
  userConfig,
  lib,
  ...
}: {
  # Power Management Configuration for Mobile devices
  powerManagement = lib.mkIf userConfig.capabilities.power {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  services.thermald = lib.mkIf userConfig.capabilities.power {
    enable = true;
  };

  services.tlp = lib.mkIf userConfig.capabilities.power {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 50;

      # Disable turbo boost on battery
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      # Runtime power management for PCI devices
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      # WiFi power saving
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  # Laptop lid and power button behavior
  services.logind = lib.mkIf userConfig.capabilities.power {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "lock";
    extraConfig = ''
      HandlePowerKey=suspend
    '';
  };

  # Enable suspend-to-RAM
  systemd.sleep.extraConfig = lib.mkIf userConfig.capabilities.power ''
    HibernateDelaySec=1800
  '';
}
