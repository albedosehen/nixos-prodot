{
  host,
  # userConfig,
  # lib,
  ...
}: {
  networking = {
    hostName = host;

    # Enable NetworkManager on desktops only
    #networkmanager.enable = userConfig.capabilities.desktop;

    # Enable systemd-networkd for non-desktops (e.g., WSL)
    #useNetworkd = lib.mkIf (!userConfig.capabilities.desktop) true;

    # Allow systemd-networkd to handle DHCP via its own config
    #useDHCP = false;

    #firewall = {
    #  enable = userConfig.security.firewall;
    #  allowedTCPPorts = [];
    #  allowedUDPPorts = [];
    #};
  };

  #systemd.network = lib.mkIf (!userConfig.capabilities.desktop) {
  #  enable = true;

  # DHCP-enabled config for WSL interface
  #  networks."10-wsl" = {
  #    matchConfig.Name = "eth0";
  #    networkConfig = {
  #      DHCP = "yes";
  #      IPv6AcceptRA = "yes";
  #      MulticastDNS = true;
  #    };
  #    dhcpConfig.UseDNS = true;
  #  };
  #};

  # Enable systemd-resolved and link resolv.conf correctly
  #services.resolved = {
  #  enable = true;
  #  dnssec = "true";
  #  domains = ["~."];
  #  fallbackDns = ["1.1.1.1" "8.8.8.8"];
  #};

  #environment.etc."resolv.conf".source = "/run/systemd/resolve/stub-resolv.conf";
}
