{
  description = "Albedosehen's NixOS WSL Dotfiles";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://cache.nixos.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    warn-dirty = false;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:albedosehen/nixvim";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixos-wsl,
    home-manager,
    treefmt-nix,
    pre-commit-hooks,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    supportedSystems = ["x86_64-linux"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowBroken = true;
        overlays = [
          (_final: _prev: {
            unstable = import nixpkgs-unstable {
              inherit system;
              config.allowUnfree = true;
              config.allowBroken = true;
            };
          })
        ];
      };

    # Import general variables and specific profiles
    vars = import ./vars.nix;
    profiles = import ./profiles.nix;

    # Configuration profile - change this to switch between profiles
    # Options: "wsl", "workstation", "mobile"
    profile = vars.selected-profile;

    # Get current profile configuration
    currentConfig = vars // profiles.${profile};

    defaults = {
      user = currentConfig.user.username;
      host = currentConfig.user.hostname;
      system = "x86_64-linux";
    };

    mkSystem = {
      user ? defaults.user,
      host ? defaults.host,
      system ? defaults.system,
      modules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs user host;
          pkgs-unstable = pkgsFor system;
          userConfig = currentConfig;
        };
        modules =
          [
            nixos-wsl.nixosModules.default
            ./modules/nixos
            ./modules/shared
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {
                  inherit inputs user host;
                  userConfig = currentConfig;
                };
                users.${user} = import ./modules/home-manager;
              };
            }
          ]
          ++ modules;
      };
  in {
    nixosConfigurations = {
      ${defaults.host} = mkSystem {};
    };

    homeConfigurations = {
      "${defaults.user}@${defaults.host}" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor defaults.system;
        extraSpecialArgs = {
          inherit inputs;
          inherit (defaults) user host;
          userConfig = currentConfig;
        };
        modules = [./modules/home-manager];
      };
    };

    packages = forAllSystems (
      system: let
        pkgs = pkgsFor system;
      in {
        docs = pkgs.callPackage ./pkgs/docs.nix {inherit self;};
        docs-profile = pkgs.callPackage ./pkgs/docs.nix {inherit self; userConfig = currentConfig // {profileName = profile;};};
        docs-local = pkgs.callPackage ./pkgs/docs-local.nix {};

        installer = pkgs.writeShellScriptBin "install-nixos-prodot" ''
          set -euo pipefail
          echo "Installing NixOS ProDot configuration..."
          sudo nixos-rebuild switch --flake ${self}#${defaults.host}
          echo "Configuration installed successfully!";
        '';

        update = pkgs.writeShellScriptBin "update-system" ''
          set -euo pipefail
          echo "Updating flake inputs..."
          nix flake update
          echo "Rebuilding system..."
          sudo nixos-rebuild switch --flake .#${defaults.host}
          echo "Update complete!"
        '';
      }
    );

    checks = forAllSystems (
      system: let
        pkgs = pkgsFor system;
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            shellcheck.enable = true;
            prettier = {
              enable = true;
              types_or = [
                "json"
                "yaml"
                "markdown"
              ];
            };
          };
        };
      in {
        inherit pre-commit-check;

        nixos-config = (mkSystem {system = system;}).config.system.build.toplevel;

        flake-check = pkgs.runCommand "flake-check" {} ''
          echo "Flake check: Using nixos-config check instead"
          touch $out
        '';

        config-validation = pkgs.runCommand "config-validation" {} ''
          echo "Configuration validation: Using nixos-config check instead"
          echo "Configuration validation passed!"
          touch $out
        '';
      }
    );

    formatter = forAllSystems (
      system:
        (treefmt-nix.lib.evalModule (pkgsFor system) {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            prettier.enable = true;
            shellcheck.enable = true;
            shfmt.enable = true;
          };
          settings.formatter = {
            prettier.includes = [
              "*.json"
              "*.yaml"
              "*.yml"
              "*.md"
            ];
            alejandra.includes = ["*.nix"];
          };
        }).config.build.wrapper
    );

    devShells = forAllSystems (
      system: let
        pkgs = pkgsFor system;
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            deadnix.enable = true;
            statix.enable = true;
            shellcheck.enable = true;
            prettier.enable = true;
          };
        };
      in {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            alejandra
            deadnix
            statix
            nixpkgs-fmt
            nix-output-monitor
            nvd
            nodePackages.prettier
            shellcheck
            shfmt
            git
            just
            jq
            yq
            mdbook
          ];

          shellHook = ''

            echo "❄️ NixOS WSL Development Environment"
            echo "Available commands:"
            echo "  nix fmt                     - Format all code"
            echo "  nix flake check             - Run all checks"
            echo "  just build                  - Build system configuration"
            echo "  just test                   - Run comprehensive tests"
            echo "  just update                 - Update and rebuild system"
            echo "  just install                - Install configuration"
            echo ""
            echo "Pre-commit hooks are available. Run 'pre-commit install' to enable them."

            alias fmt="nix fmt"
            alias check="nix flake check"
            alias build="nix build .#nixosConfigurations.${defaults.host}.config.system.build.toplevel"
            alias test="nix flake check --show-trace"
            alias update="nix run .#update"
            alias install="nix run .#installer"

            ${pre-commit-check.shellHook}
          '';
        };
      }
    );

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.installer}/bin/install-nixos-prodot";
        meta = {
          description = "Install NixOS ProDot configuration";
          mainProgram = "install-nixos-prodot";
        };
      };

      update = {
        type = "app";
        program = "${self.packages.${system}.update}/bin/update-system";
        meta = {
          description = "Update and rebuild system configuration";
          mainProgram = "update-system";
        };
      };
    });
  };
}
