# NixOS Profile-Based Configuration

I've built this comprehensive, profile-aware NixOS configuration to work seamlessly across multiple computing environments. Whether you're developing on WSL2, running a desktop workstation, or using a laptop, I've designed this to provide optimized setups with shared tooling and modular architecture that just works.

## 🚀 Quick Start

I've made it super easy to get started - just choose your environment and you'll be up and running in minutes:

### WSL2 Users (Windows)

```bash
# 1. Clone the repository
git clone https://github.com/your-repo/nixos-wsl-dotfiles.git
cd nixos-wsl-dotfiles

# 2. Preview and apply WSL profile
./modules/nixos/scripts/switch-profile.sh wsl --dry-run
./modules/nixos/scripts/switch-profile.sh wsl --rebuild

# 3. Start developing
just dev
```

### NixOS Desktop Users

```bash
# 1. Clone configuration
git clone https://github.com/your-repo/nixos-wsl-dotfiles.git /etc/nixos/nixos-wsl-dotfiles
cd /etc/nixos/nixos-wsl-dotfiles

# 2. Choose your profile
./modules/nixos/scripts/switch-profile.sh workstation --dry-run  # For desktop
./modules/nixos/scripts/switch-profile.sh mobile --dry-run       # For laptop

# 3. Apply configuration
./modules/nixos/scripts/switch-profile.sh workstation --rebuild  # Or mobile
```

## 📋 Available Profiles

I've created three main profiles that cover most use cases:

| Profile         | Environment        | Best For           | Key Features                                  |
| --------------- | ------------------ | ------------------ | --------------------------------------------- |
| **wsl**         | WSL2 on Windows    | Windows developers | Docker, minimal overhead, Windows integration |
| **workstation** | Native | Desktop systems    | Complete DE, GPU support, full dev stack      |
| **mobile**      | Native | Mobile devices   | Power management, hybrid graphics, security   |

## 🛠️ Essential Commands

```bash
# Profile Management
./modules/nixos/scripts/switch-profile.sh --list     # List all profiles
./modules/nixos/scripts/switch-profile.sh --current  # Show current profile
./modules/nixos/scripts/switch-profile.sh <profile> --dry-run  # Preview changes

just fix      # Format & apply fixes to raised issues
just check    # Validate flake
just lint     # Lint the project
just test     # Run full test against configuration
just build    # Build system configuration
just help     # See all commands

# Applying changes
just nos      # Applies nixosConfiguration (NixOS)
just nhs      # Applies homeConfiguration (Home Manager)

# Git Profile Management
git-profile list            # List available git profiles
git-profile switch work     # Switch to work git profile
git whoami                  # Show current git user
```

## 📚 Documentation

I've put together comprehensive documentation that covers everything you need to know. You can generate and view it locally:

```bash
# Generate and view complete documentation
just docs
```

Here's what I've documented for you:

- **[Installation Guide](docs/src/installation.md)** - Detailed setup instructions for all environments
- **[Profile Overview](docs/src/profiles.md)** - Complete profile capabilities and comparisons
- **[Configuration Guide](docs/src/configuration.md)** - Customization and advanced configuration
- **[Git Management](docs/src/git-management.md)** - Git profile system and workflows
- **[Development Guide](docs/src/development.md)** - Development environment and tools
- **[Testing](docs/src/testing.md)** - Testing and validation procedures
- **[Contributing](docs/src/contributing.md)** - Contribution guidelines and development setup

## 🏗️ Project Structure

I've organized everything in a logical structure that's easy to navigate:

```
nixos-prodot/
├── flake.nix                 # Main flake configuration
├── profiles.nix              # System profile definitions
├── vars.nix                  # Shared variables and git profiles
├── justfile                  # Development commands
├── modules/
│   ├── nixos/               # System-level configuration
│   ├── home-manager/        # User environment configuration
│   └── shared/              # Shared utilities
├── docs/                    # Generated documentation
└── pkgs/                    # Custom user-defined packages
```

## 🔧 Quick Customization

I've made it easy to customize this configuration for your needs. Simply create a new branch and modify [`vars.nix`](vars.nix) with your own system settings. You can further customize your configuration within [`profiles.nix`](profiles.nix) and [`flake.nix`](flake.nix)


### Adding a New Profile
The pre-built profiles should be sufficient for most use-cases but if you'd like to make your own, all you need to do is define it in [`profiles.nix`](profiles.nix) and update the `selected-profile` to the name of the custom profile in [`vars.nix`](vars.nix).

1. Edit [`profiles.nix`](profiles.nix) to define your profile:

   ```nix
   solarflare = {
     user = { username = "user"; hostname = "my-hostname"; };
     capabilities = { /* define features */ };
   };
   ```

2. Test the new profile by updating the `justfile` to reference the custom `#solarflare` profile and running:
   ```bash
   just test
   ```

### Add Git Profiles

You can easily add new git configurations by editing [`vars.nix`](vars.nix):

```nix
gitProfiles = {
  client = {
    userName = "Your Name";
    userEmail = "client@company.com";
  };
};
```

### Where are all the languages?
This project practices using `nix-direnv` and `flakes` and scoped to their respective projects for isolated and reproducible environments. Therefor what these dotfiles provide are the base settings for getting a development environment going. You will still need to add a `flake.nix` and a `.envrc` to your projects to isolate the environments.

I've provided several [templates](/templates) that can easily be copied to a project and modified for getting up and running.

```bash
cp ~/.nixos-prodot/templates/nodejs.nix ~/<path-to-your-project>/flake.nix
echo "use flake" > ~/<path-to-your-project>/.envrc
cd ~/<path-to-your-project>
# Modify the ~/<path-to-your-project>/flake.nix to add, remove, etc any additional dependencies

git add flake.nix .envrc
direnv allow
```

Your isolated environment is ready with `NodeJS` and `NPM` installed. Don't forget to ignore the `.direnv/` so your project stays clean.

## 🆘 Need Help?

If you run into any issues, here's how I recommend troubleshooting:

- **Configuration Problems**: Run `just test` to validate your setup
- **Detailed Troubleshooting**: I've provided [documentation](docs/) for information regarding this project setup. `just docs # Generates the documentation` `just docs-serve # Start the documentation server`
- **NixOS Resources**: These official resources are incredibly helpful:
  - [NixOS Manual](https://nixos.org/manual/nixos/stable/)
  - [Home Manager Documentation](https://nix-community.github.io/home-manager/)
  - [NixOS Wiki](https://nixos.wiki/)

## 🤝 Contributing

Always happy to have contributers to the dotfiles! Here's how:

1. Make your changes
2. Run `just fmt` and `just test`
3. Submit a pull request

For detailed contribution guidelines, see the [Contributing Guide](docs/src/contributing.md) in the comprehensive documentation.

---
