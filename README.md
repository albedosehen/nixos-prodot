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
| **workstation** | Full NixOS desktop | Desktop systems    | Complete DE, GPU support, full dev stack      |
| **mobile**      | NixOS laptops      | Portable devices   | Power management, hybrid graphics, security   |

## 🛠️ Essential Commands

```bash
# Profile Management
./modules/nixos/scripts/switch-profile.sh --list     # List all profiles
./modules/nixos/scripts/switch-profile.sh --current  # Show current profile
./modules/nixos/scripts/switch-profile.sh <profile> --dry-run  # Preview changes

# Development
just dev      # Enter development shell
just fmt      # Format all code
just test     # Run comprehensive tests
just build    # Build system configuration

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
nixos-wsl-dotfiles/
├── flake.nix                 # Main flake configuration
├── profiles.nix              # System profile definitions
├── vars.nix                  # Shared variables and git profiles
├── justfile                  # Development commands
├── modules/
│   ├── nixos/               # System-level configuration
│   ├── home-manager/        # User environment configuration
│   └── shared/              # Shared utilities
├── docs/                    # Comprehensive documentation
├── pkgs/                    # Custom packages
└── tests/                   # Testing and validation
```

## 🔧 Quick Customization

I've made it easy to customize this configuration for your needs.

### Add a New Profile

1. Edit [`profiles.nix`](profiles.nix) to define your profile:

   ```nix
   myprofile = {
     user = { username = "user"; hostname = "my-hostname"; };
     capabilities = { /* define features */ };
   };
   ```

2. Test the new profile:
   ```bash
   ./modules/nixos/scripts/switch-profile.sh myprofile --dry-run
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

## 🆘 Need Help?

If you run into any issues, here's how I recommend troubleshooting:

- **Quick Issues**: Check your current profile with `./modules/nixos/scripts/switch-profile.sh --current`
- **Configuration Problems**: Run `just test` to validate your setup
- **Detailed Troubleshooting**: I've documented common issues in the [comprehensive documentation](docs/) - just run `just docs`
- **NixOS Resources**: These official resources are incredibly helpful:
  - [NixOS Manual](https://nixos.org/manual/nixos/stable/)
  - [Home Manager Documentation](https://nix-community.github.io/home-manager/)
  - [NixOS Wiki](https://nixos.wiki/)

## 🤝 Contributing

I'd love your contributions! Here's how:

1. Make your changes
2. Run `just fmt` and `just test`
3. Submit a pull request

For detailed contribution guidelines, see the [Contributing Guide](docs/src/contributing.md) in the comprehensive documentation.

---

**Ready to start?** Choose your profile above and follow the quick start guide! For detailed information, generate the comprehensive documentation with `just docs`.
