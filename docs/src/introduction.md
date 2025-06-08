# Introduction

Welcome to albedosehen's NixOS Profile-Based Dotfile Configuration system! This documentation covers
a comprehensive, modular NixOS configuration that supports multiple computing environments
through simple profile management.

## Overview

This configuration provides three optimized profiles:

- **WSL Profile**: Optimized for WSL2 development on Windows (Perfect for beginners getting started with NixOS using WSL2)
- **Workstation Profile**: Full-featured NixOS desktop environment for full workstation capabilities
- **Mobile Profile**: Power-optimized configuration for laptops
- **Custom Profiles**: Easily extendable for custom configurations. Add your own profiles easily by modifying `profiles.nix`.

## Key Features

- 🎯 **Profile-Aware Configuration**: Conditional module loading based on environment
- 🔄 **Easy Profile Switching**: Simple command-line tools for profile management
- 🧪 **Comprehensive Testing**: Built-in validation and testing framework
- 🎨 **Automated Formatting**: Code formatting with alejandra and prettier
- 🔍 **Static Analysis**: Linting with statix and deadnix
- 🚀 **CI/CD Ready**: GitHub Actions and pre-commit hooks
- 📦 **Modular Architecture**: Clean separation of concerns
-  ⚡ **Performance Optimized**: Efficient build caching and binary substitution
- 🔒 **Security Hardened**: Profile-specific security configurations
- 📚 **Living Documentation**: Auto-generated, profile-aware docs

## Quick Navigation

- **Getting Started** Start with [Installation Guide](./installation.md)
- **Profile Settings** View [Profile Overview](./profiles.md)
- **Profile Switching** View [Profile Switching](./switching.md)
- **Development** View [Development](./development.md)