# Profile Switching Guide

The profile switching system allows you to easily transition between different
computing environments while maintaining consistent configurations.

## Profile Switch Script

The main tool for profile management is `./modules/nixos/scripts/switch-profile.sh`.

### Basic Usage

```bash
# Show current profile and configuration
./modules/nixos/scripts/switch-profile.sh --current

# List all available profiles with details
./modules/nixos/scripts/switch-profile.sh --list

# Preview changes without applying (recommended)
./modules/nixos/scripts/switch-profile.sh <profile> --dry-run

# Switch profile and rebuild system
./modules/nixos/scripts/switch-profile.sh <profile> --rebuild

# Switch profile without rebuilding (requires manual rebuild later)
./modules/nixos/scripts/switch-profile.sh <profile>
```

### Profile Switch Examples

```bash
# Switch from any profile to WSL for Windows development
./modules/nixos/scripts/switch-profile.sh wsl --rebuild

# Move to full workstation setup
./modules/nixos/scripts/switch-profile.sh workstation --dry-run
./modules/nixos/scripts/switch-profile.sh workstation --rebuild

# Configure for mobile/laptop use
./modules/nixos/scripts/switch-profile.sh mobile --rebuild
```

## What Changes During Profile Switch

### System Configuration Changes

- **Hostname**: Each profile has a distinct hostname

  - `wsl`: `nixos-wsl`
  - `workstation`: `nixos-workstation`
  - `mobile`: `nixos-mobile`

- **Capabilities**: Different features enabled/disabled

  - WSL integration (wsl only)
  - Desktop environment (workstation, mobile)
  - GPU acceleration (workstation, mobile)
  - Power management (mobile only)

- **Security Settings**: Profile-appropriate security measures
  - Firewall configuration
  - AppArmor policies
  - Kernel module restrictions

### Development Environment

- **Available Tools**: Some tools may be enabled/disabled per profile
- **Performance Optimizations**: Profile-specific tuning
- **Resource Management**: Different resource allocation strategies

### What Stays the Same

- **Git Profiles**: All system profiles share the same git profile system
- **User Data**: Personal files and configurations remain unchanged
- **Core Tools**: Essential development tools available across profiles

## Git Profile Management

Git profiles are managed separately from system profiles:

```bash
# List available git profiles
git-profile list

# Switch git profiles (independent of system profile)
git-profile switch personal
git-profile switch work

# Check current git configuration
git whoami
git-profile current
```

## Advanced Profile Management

### Manual Configuration Override

You can temporarily override profile settings by editing `flake.nix` directly:

```nix
# In flake.nix, change the profile line
profile = "workstation";  # Change to desired profile
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake .
```

### Custom Profile Development

Create custom profiles by:

1. **Adding to `profiles.nix`**:

   ```nix
   myprofile = {
     user = { username = "user"; hostname = "my-hostname"; };
     capabilities = { /* define capabilities */ };
     # ... other configuration
   };
   ```

2. **Testing the profile**:

   ```bash
   ./modules/nixos/scripts/switch-profile.sh myprofile --dry-run
   ```

3. **Applying when ready**:
   ```bash
   ./modules/nixos/scripts/switch-profile.sh myprofile --rebuild
   ```

## Rollback and Recovery

### Automatic Backups

The switch script automatically creates backups:

- `flake.nix.backup.TIMESTAMP` files are created before each switch
- Old backups are automatically cleaned up (keeps 3 most recent)

### Manual Rollback

```bash
# Restore from backup
cp flake.nix.backup.TIMESTAMP flake.nix
sudo nixos-rebuild switch --flake .

# Or use NixOS generations
sudo nixos-rebuild switch --rollback
```

### Validation Before Switch

Always validate configuration before switching:

```bash
# Check configuration syntax
nix flake check

# Test build without applying
sudo nixos-rebuild dry-build --flake .

# Preview with dry-run
./modules/nixos/scripts/switch-profile.sh <profile> --dry-run
```

## Profile Switch Checklist

Before switching profiles:

- [ ] **Backup important work**: Ensure git repos are pushed
- [ ] **Preview changes**: Use `--dry-run` to understand impact
- [ ] **Check capabilities**: Verify the target profile meets your needs
- [ ] **Plan rebuild time**: System rebuilds can take 5-30 minutes
- [ ] **Verify network**: Ensure stable connection for downloads

After switching profiles:

- [ ] **Verify system state**: Check that expected capabilities are working
- [ ] **Test development environment**: Run `just dev` and verify tools
- [ ] **Update git profile**: Switch git profile if needed
- [ ] **Document changes**: Note any manual configurations needed
