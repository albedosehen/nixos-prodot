# Configuration

This section covers how to configure and customize your NixOS profile-based setup.

## Profile Configuration

Profiles are defined in `profiles.nix` and control which capabilities are enabled
for different computing environments.

### Current Profile

Check your current profile:

```bash
./modules/nixos/scripts/switch-profile.sh --current
```

### Switching Profiles

See the [Profile Switching Guide](./switching.md) for detailed instructions.

## Customization

### Adding Custom Packages

Add packages to your profile by editing the appropriate module files:

```nix
# In modules/shared/pkgs.nix
environment.systemPackages = with pkgs; [
  # Add your packages here
  firefox
  vscode
];
```

### Custom Git Profiles

Edit `vars.nix` to add new git profiles:

```nix
gitProfiles = {
  # ... existing profiles
  custom = {
    userName = "Your Name";
    userEmail = "your@email.com";
    signingKey = null;
    extraConfig = {};
  };
};
```

### Module Configuration

Each profile can enable/disable specific modules. Check the profile definitions
in `profiles.nix` to see which capabilities are available.

## Advanced Configuration

### Custom Profiles

Create custom profiles by adding them to `profiles.nix`:

```nix
myprofile = {
  user = { username = "user"; hostname = "my-hostname"; };
  capabilities = {
    # Define which features to enable
    desktop = true;
    docker = false;
    # ... other capabilities
  };
};
```

### Environment Variables

Set custom environment variables in your profile configuration.

### Service Configuration

Configure systemd services and other system-level settings through the
modular configuration system.
