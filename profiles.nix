let
  vars = import ./vars.nix;
in {
  wsl = {
    user = vars.user;
    gitProfiles = vars.gitProfiles;

    capabilities = {
      wsl = true;
      desktop = false;
      laptop = false;
      power = false;
      nvidia = false;
      amd = false;
      intel = false;
      docker = true;
    };

    security = {
      level = "minimal";
      hardening = false;
      apparmor = false;
      auditd = false;
      firewall = false;
    };

    system = {
      bootLoader = "none";
      kernel = "default";
      filesystem = "ext4";
    };
  };

  workstation = {
    user = vars.user;
    gitProfiles = vars.gitProfiles;

    capabilities = {
      wsl = false;
      desktop = true;
      laptop = false;
      power = false;
      nvidia = true;
      amd = false;
      intel = true;
      docker = true;
    };

    security = {
      level = "standard";
      hardening = true;
      apparmor = true;
      auditd = true;
      firewall = true;
    };

    system = {
      bootLoader = "systemd-boot";
      kernel = "latest";
      filesystem = "btrfs";
    };
  };

  mobile = {
    user = vars.user;
    gitProfiles = vars.gitProfiles;

    capabilities = {
      wsl = false;
      desktop = true;
      laptop = true;
      power = true;
      nvidia = true;
      amd = false;
      intel = true;
      docker = true;
    };

    security = {
      level = "high";
      hardening = true;
      apparmor = true;
      auditd = true;
      firewall = true;
    };

    system = {
      bootLoader = "systemd-boot";
      kernel = "latest";
      filesystem = "btrfs";
    };
  };
}
