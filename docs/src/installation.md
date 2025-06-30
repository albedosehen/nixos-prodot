# Installation Guide

This guide provides step-by-step instructions for setting up the NixOS configuration
across different environments.

## Prerequisites

### For WSL2 Users (Windows)

1. **Enable WSL2 Features**:
   Just do a search for setting this up.

2. **Update WSL**
   Make sure you are an administrator and install the WSL preview update from the [Microsoft Store](https://aka.ms/wslstorepage).

3. **Install NixOS distribution**:
   You'll need to download the NixOS WSL image from the [NixOS WSL repository](https://github.com/nix-community/NixOS-WSL).

   ```powershell
   wsl --install --from-file nixos.wsl # use --name param if to override the default WSL distro name (NixOS)
   ```

4. **(Automated): Setup**:
   After installing the NixOS WSL distribution, you can run the following command from NixOS to quickly set up your system:

   ```bash
   # curl request to download the setup script that automates downloading and installing the configuration
   curl -L https://raw.githubusercontent.com/albedosehen/nixos-prodot/scripts/auto-setup.sh | bash

   0. Pre-setup & validation
     a. Check for requirements
       - Required tools`curl` `git` `direnv` `nix`
       - flakes enabled, experimental features enabled
       - Use a development shell or another Nix method for reproducing the necessary environment? Let AI figure this out.
       - If anything is missing, prompt the user to help resolve it
     b. Check for existing configuration
       - If an existing configuration is found (~/.nixos-prodot), prompt the user to confirm if they want to overwrite it
       - If the user confirms, proceed with the setup
       - If the user declines, exit the script
     c. If no existing configuration found
       - Ask the user if they have a fork of the repository
       - If yes, clone the forked repository into ~/.nixos-prodot
         - Prompt for the fork URL
         - Clone the repository using `git clone <fork-url> ~/.nixos-prodot`
         - Ask user which profile to apply and switch to it. If there are any errors the user will have to manually resolve it.
     e. For cloned repository from main branch:
       - cd into ~/.nixos-prodot
       - Allow and load the development shell and then proceed to the next step

     Improvement for AI: Maybe setup and enter a development shell to ensure all dependencies are available prior to running the setup script.

   1. You'll be asked the following questions:
   - **Username**: Your desired username (default: `nixos`)
   - **Hostname**: Your desired hostname (default: `nixos-wsl`)
   - **Profile**: Choose from `wsl`, `workstation`, or `mobile` (default: `wsl`)
   - **Git Profile**: Prompt to update personal git profile values:
     - **Provider**: Select from `github` or `bitbucket` (default: `github`)
     - **Name**: Your full name
     - **Email**: Your email address
     - **SSH Key**: Optionally generate a new SSH key for git access
     - **Signing Key**: Optionally generate a GPG key for commit signing
   - **Git Profile**: Ask to set up 'work' profile
     - Same as above, but for the work profile

   2. Update vars.nix with values provided by the user
   3. Update justfile with the selected profile for the build, install, and switch commands
   4. Add the changes to the git index
   5. Commit the changes with a message like "Initial setup for NixOS WSL configuration" (I don't want the user to push to my repository, so they will need to push to their own fork) The script can attempt to fork the repository if it doesn't exist, but it will require the user to have a GitHub account and be logged in.
   6. Run the `just install` command to apply the configuration
   7. Prompt the user to reboot NixOS WSL with `wsl -t NixOS` and to apply the change with `wsl -d NixOS --system root exit`
   8. To complete the setup, the user must run `just nhs` or `nh home switch .` from the `~/.nixos-prodot` directory to apply the home-manager configuration.
   9. They are done.
   ```

### For Native NixOS Users

I'll assume you already have NixOS installed and ready to go.

1. **Enable Flakes**: Add to `/etc/nixos/configuration.nix`:

   ```nix
   nix.settings.experimental-features = [ "nix-command" "flakes" ];
   ```

2. **Rebuild**: `sudo nixos-rebuild switch`

## Configuration Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/albedosehen/nixos-prodot ~/.nixos-prodot
cd ~/.nixos-prodot
```

### Step 2: Activate the development environment

```bash
direnv allow # Allow direnv to load the environment
```

### Step 3:

```bash
# View all available profiles
./modules/nixos/scripts/switch-profile.sh --list

# Preview profile changes (recommended)
./modules/nixos/scripts/switch-profile.sh <profile> --dry-run

# Apply profile (choose one):
./modules/nixos/scripts/switch-profile.sh wsl --rebuild        # For WSL2
./modules/nixos/scripts/switch-profile.sh workstation --rebuild # For desktop
./modules/nixos/scripts/switch-profile.sh mobile --rebuild     # For laptop
```

### Step 3: Development Environment Setup

```bash
# Enter development shell with all tools
just dev

# Verify installation
just check
just build
```

## Verification

After installation, verify your setup:

```bash
# Check current profile
./modules/nixos/scripts/switch-profile.sh --current

# Verify system build
sudo nixos-rebuild dry-build --flake .

# Test development environment
just test
```

## Troubleshooting

### Common Issues

**Flakes not enabled**:

```bash
# Add to ~/.config/nix/nix.conf or /etc/nix/nix.conf
experimental-features = nix-command flakes
```

**Permission issues**:

```bash
# Ensure proper ownership
sudo chown -R $USER:$USER ~/.config/nix
```

**WSL-specific issues**:

- Ensure WSL2 is properly configured
- Check Windows Firewall settings if networking issues occur
- Restart WSL: `wsl --shutdown` then restart

### Getting Help

- Check the [modules documentation](./modules.md)
- Review [profile switching guide](./switching.md)
- Examine test results: `just test`
