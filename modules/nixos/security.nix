{userConfig, ...}: {
  security = {
    apparmor.enable = userConfig.security.apparmor;

    protectKernelImage = true;

    allowUserNamespaces = true;

    lockKernelModules = userConfig.security.hardening;

    sudo = {
      enable = true;
      execWheelOnly = true;
      configFile = ''
        Defaults lecture=never
        Defaults pwfeedback
        Defaults env_keep += "EDITOR PATH"
        Defaults timestamp_timeout=30
      '';
    };
  };

  boot = {
    kernel.sysctl = {
      "kernel.dmesg_restrict" = 1;
      "net.core.bpf_jit_harden" = 2;
      "kernel.kptr_restrict" = 2;
      "kernel.unprivileged_bpf_disabled" = 1;
      "net.ipv4.conf.all.log_martians" = true;
      "net.ipv4.conf.all.send_redirects" = false;
      "net.ipv4.conf.all.accept_redirects" = false;
      "net.ipv6.conf.all.accept_redirects" = false;
    };
  };

  systemd = {
    coredump.enable = false;

    extraConfig = ''
      DefaultTimeoutStopSec=10s
      DefaultLimitNOFILE=1048576
    '';
  };
}
