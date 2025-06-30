# Profile Overview

This configuration system uses three distinct profiles to optimize NixOS for different
computing environments. Each profile is carefully tuned for its intended use case.

## Available Profiles

### WSL Profile (`wsl`)

**Environment**: WSL2 on Windows
**Use Case**: Development environment within Windows

**Capabilities:**

- ✅ WSL integration and optimizations
- ✅ Docker and containerization tools
- ✅ Full development stack (languages, editors, shells)
- ❌ Desktop environment (uses Windows host)
- ❌ Audio/Bluetooth (managed by Windows)
- ❌ GPU acceleration (uses Windows drivers)

**System Configuration:**

- Hostname: `nixos-wsl`
- Firewall: Disabled (Windows manages networking)
- Security: Minimal footprint for development
- Performance: Optimized for fast development workflows

### Workstation Profile (`workstation`)

**Environment**: Full NixOS desktop installation
**Use Case**: Primary desktop workstation with full capabilities

**Capabilities:**

- ✅ Complete desktop environment
- ✅ NVIDIA GPU support with CUDA
- ✅ Audio (PipeWire) and Bluetooth
- ✅ Full development and gaming stack
- ✅ Docker and Kubernetes
- ✅ Security hardening

**System Configuration:**

- Hostname: `nixos-workstation`
- Desktop: Full-featured with hardware acceleration
- Security: Comprehensive hardening
- Performance: Optimized for high performance computing

### Mobile Profile (`mobile`)

**Environment**: NixOS on laptops and portable devices
**Use Case**: Portable development with power optimization

**Capabilities:**

- ✅ Desktop environment with power optimizations
- ✅ Hybrid NVIDIA graphics (Intel + NVIDIA)
- ✅ Advanced power management (TLP)
- ✅ Audio and Bluetooth
- ✅ Enhanced security (kernel module locking)
- ❌ Docker (disabled for battery conservation. Override if needed)

**System Configuration:**

- Hostname: `nixos-mobile`
- Power: Aggressive power management and thermal control
- Security: Maximum security configuration
- Performance: Battery-optimized with performance modes

## Profile Selection Guide

| Scenario                   | Recommended Profile     | Key Benefits                                 |
| -------------------------- | ----------------------- | -------------------------------------------- |
| Windows + WSL2 Development | `wsl`                   | Native Windows integration, minimal overhead |
| Linux Gaming/Workstation   | `workstation`           | Full GPU support, maximum performance        |
| Laptop/Travel Development  | `mobile`                | Extended battery life, thermal management    |
| Server/Headless Setup      | Custom (based on `wsl`) | Minimal footprint, no desktop                |

## Shared Configuration

All profiles share:

- Git profile management system
- Core development tools and languages
- Security baseline configurations
- Testing and validation framework
- Documentation generation

The difference is in capability enablement and optimization focus.
