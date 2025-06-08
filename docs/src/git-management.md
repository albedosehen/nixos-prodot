# Git Profile Management

The git profile system allows you to maintain separate git identities that work
across all system profiles. This is useful for separating personal and work
contributions.

## Available Git Profiles

Git profiles are defined in `vars.nix` and shared across all system profiles:

### Personal Profile (Default)
- **Name**: Shon Thomas
- **Email**: my@email.com
- **Use Case**: Personal projects and open source contributions

### Work Profile
- **Name**: Shon Thomas
- **Email**: mys@company.com
- **SSH Key**: Uses separate work SSH key (`~/.ssh/work_key`)
- **Use Case**: Corporate and work-related development

## Git Profile Commands

### Viewing Git Profiles

```bash
# List all available git profiles
git-profile list

# Show current active git profile
git-profile current

# Show current git user configuration
git whoami
```

### Switching Git Profiles

```bash
# Switch to personal profile
git-profile switch personal

# Switch to work profile
git-profile switch work

# Verify the switch worked
git whoami
```

### Example Output

```bash
$ git-profile list
Available git profiles:
  personal (default):
    Name: myusername
    Email: my@email.com

  work:
    Name: Shon Thomas
    Email: shon.thomas@company.com
    SSH Command: ssh -i ~/.ssh/work_key

$ git-profile switch work
Switched to git profile: work

$ git whoami
Shon Thomas <shon.thomas@company.com>
```

## Profile Configuration

Git profiles are configured in `vars.nix`:

```nix
gitProfiles = {
  default = "personal";  # Default profile to use

  personal = {
    userName = "myusername";
    userEmail = "my@email.com";
    signingKey = null;  # Add GPG key if needed
    extraConfig = {};
  };

  work = {
    userName = "Shon Thomas";
    userEmail = "shon.thomas@company.com";
    signingKey = null;  # Add work GPG key if needed
    extraConfig = {
      core.sshCommand = "ssh -i ~/.ssh/work_key";
    };
  };
};
```

## Adding New Git Profiles

To add a new git profile:

1. **Edit `vars.nix`**:
   ```nix
   gitProfiles = {
     # ... existing profiles
     client = {
       userName = "Your Name";
       userEmail = "client@company.com";
       signingKey = null;
       extraConfig = {
         core.sshCommand = "ssh -i ~/.ssh/client_key";
       };
     };
   };
   ```

2. **Rebuild the system**:
   ```bash
   sudo nixos-rebuild switch --flake .
   ```

3. **Use the new profile**:
   ```bash
   git-profile switch client
   ```

## Advanced Configuration

### GPG Signing

To enable commit signing:

1. **Add GPG key to profile**:
   ```nix
   personal = {
     userName = "Your Name";
     userEmail = "personal@email.com";
     signingKey = "YOUR_GPG_KEY_ID";
     extraConfig = {
       commit.gpgsign = true;
       gpg.program = "gpg2";
     };
   };
   ```

2. **Ensure GPG is configured**:
   ```bash
   # Import your GPG key
   gpg --import your-key.asc

   # Test signing
   echo "test" | gpg --clearsign
   ```

### SSH Key Management

Different profiles can use different SSH keys:

```nix
work = {
  # ... other config
  extraConfig = {
    core.sshCommand = "ssh -i ~/.ssh/work_key -o IdentitiesOnly=yes";
  };
};
```

Make sure your SSH keys are properly configured:

```bash
# Generate work SSH key
ssh-keygen -t ed25519 -f ~/.ssh/work_key -C "work@company.com"

# Add to SSH agent
ssh-add ~/.ssh/work_key

# Test connection
ssh -i ~/.ssh/work_key -T git@github.com
```

## Integration with System Profiles

Git profiles work seamlessly across all system profiles:

- **WSL Profile**: Use any git profile for Windows development
- **Workstation Profile**: Switch git profiles for different projects
- **Mobile Profile**: Maintain consistent git identity while mobile

### Workflow Example

```bash
# Start with personal profile on workstation
./modules/nixos/scripts/switch-profile.sh workstation --rebuild
git-profile switch personal

# Switch to work profile for work projects
git-profile switch work
cd ~/work/company-project
git commit -m "Work changes"  # Uses work identity

# Switch back to personal for open source
git-profile switch personal
cd ~/projects/open-source
git commit -m "Personal contribution"  # Uses personal identity
```

## Troubleshooting

### Git Identity Issues

```bash
# Check current git configuration
git config --global --list | grep user

# Verify profile switch worked
git whoami

# Manually set if needed (temporary)
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

### SSH Key Issues

```bash
# Test SSH connection
ssh -T git@github.com

# Check SSH agent
ssh-add -l

# Force specific key
ssh -i ~/.ssh/specific_key -T git@github.com
```

### Profile Persistence

Git profiles persist across:
- Terminal sessions
- System reboots
- Profile switches
- Home manager rebuilds

The active profile is stored in your environment and will be restored automatically.