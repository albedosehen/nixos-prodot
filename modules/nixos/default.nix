{
  user,
  host,
  ...
}: {
  imports = [
    ./wsl.nix
    ./system.nix
    #./security.nix
    #./networking.nix
    ./users.nix
    ./nix.nix
    ./desktop.nix
    ./power.nix
  ];

  system.stateVersion = "25.05";

  assertions = [
    {
      assertion = user != null && user != "";
      message = "User must be defined";
    }
    {
      assertion = host != null && host != "";
      message = "Host must be defined";
    }
  ];

  system.activationScripts.validateConfig = {
    text = ''
      echo "Validating NixOS configuration..."
      if [ -z "${user}" ]; then
        echo "Error: User not defined"
        exit 1
      fi
      if [ -z "${host}" ]; then
        echo "Error: Host not defined"
        exit 1
      fi
      echo "Configuration validation passed"
    '';
    deps = [];
  };
}
