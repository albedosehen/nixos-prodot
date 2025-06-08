default_cmd := "help"

help:
    @echo ""
    @echo "NixOS Dotfiles"
    @echo "========================================="
    @echo "Development:"
    @echo "  just dev      - Enter development shell"
    @echo "  just fmt      - Format all code"
    @echo "  just check    - Run all checks and tests"
    @echo "  just build    - Build system configuration"
    @echo "  just test     - Run comprehensive tests"
    @echo "  just lint     - Run linting and "
    @echo ""
    @echo "System Management:"
    @echo "  just install  - Install system configuration"
    @echo "  just update   - Update flake inputs and rebuild"
    @echo "  just switch   - Switch to new configuration"
    @echo "  just gc       - Run garbage collection"
    @echo ""
    @echo "CI/CD:"
    @echo "  just ci       - Run CI pipeline locally"
    @echo ""
    @echo "Documentation:"
    @echo "  just docs-generate - Generate documentation source files from templates"
    @echo "  just docs-build    - Build HTML docs from local source files"
    @echo "  just docs-serve    - Start local documentation server"
    @echo "  just docs          - Generate profile-aware documentation (Nix build)"
    @echo ""

dev:
    nix develop

## SYSTEM MGMT
build:
    nix build .#nixosConfigurations.nixos.config.system.build.toplevel

install:
    sudo nixos-rebuild switch --flake .#nixosConfigurations.nixos.config.system.build.toplevel

switch:
    sudo nixos-rebuild switch --flake .#nixosConfigurations.nixos.config.system.build.toplevel

update:
    nix flake update
    just switch

gc:
    sudo nix-collect-garbage -d
    nix-collect-garbage -d

## FLAKE
fmt:
    nix fmt

fix:
    nix fmt
    alejandra .
    statix --fix .

check:
    @echo "[flake]: checking configuration"
    nix flake check --show-trace

    if nix eval --json .#nixosConfigurations.nixos.config.system.build.toplevel; then \
        echo "✅ [flake]: configuration check passed"; \
    else \
        echo "❌ [flake]: configuration check failed"; \
        exit 1; \
    fi

    if nix flake show >/dev/null 2>&1; then \
        echo "✅ [flake]: flake structure passed"; \
    else \
        echo "❌ [flake]: Flake structure failed"; \
        exit 1; \
    fi


## LINTERS
alejandra:
    @echo "[lint]: Checking format"
    if alejandra --check .; then \
        @echo "✅ [lint]: alejandra formatting check passed"; \
    else \
        @echo "❌ [lint]: alejandra formatting issues found"; \
        exit 1; \
    fi

deadnix:
    @echo "[lint]: Checking for deadcode"
    if deadnix --check .; then \
        @echo "✅ [lint]: deadnix checks passed"; \
    else \
        @echo "❌ [lint]: deadnix issues found"; \
        exit 1; \
    fi

statix:
    @echo "[lint]: Linting with statix "
    if statix --check .; then \
        @echo "✅ [lint]: statix passed"; \
    else \
        @echo "❌ [lint]: statix issues found (Hint: just fix)"; \
        exit 1; \
    fi

shellcheck:
    @echo "[lint]: Linting shell scripts"
    if shellcheck ./**/*.sh; then \
        @echo "✅ [lint]: shellcheck passed"; \
    else \
        @echo "❌ [lint]: shellcheck issues found (Hint: just fix)"; \
        exit 1; \
    fi

lint:
    @echo "[lint]: Performing full project lint"
    just statix
    just deadnix
    just alejandra
    just shellcheck

## TESTS
test:
    @echo "[flake]: Running tests..."
    just check
    just lint
    just build
    @echo "All tests passed"

## CI/CD
ci:
    @echo "Running CI pipeline..."
    just fix
    just test
    @echo "CI pipeline completed successfully!"

## UTILS
nos:
    @echo "[nh]: Applying system profile configuration"
    sudo nh os switch .
    @echo "[nh]: (WSL2): Run the following commands to apply the changes. Replace <distro_name> with your actual WSL distribution name:"
    @echo "        wsl -t <distro_name> && wsl -d <distro_name> --system --user root exit && wsl -d <distro_name>"
    @echo ""

nhs:
    @echo "[nh]: Applying user profile configuration"
    sudo nh home switch . && . ~/.zshrc
    @echo ""

## DOCS
docs-generate:
    @echo "🔧 Generating documentation source files..."
    ./scripts/generate-docs.sh

docs-build:
    @echo "📖 [docs]: Building documentation from local files..."
    if [ ! -f "docs/book.toml" ]; then \
        @echo "❌ [docs]: No local documentation files found."; \
        @echo "   Run 'just docs-generate' first to create source files."; \
        exit 1; \
    fi
    @nix build .#docs-local
    @echo "✅ [docs]: Documentation built in result/"

docs-serve:
    @echo "🌐 [docs]: Starting documentation development server..."
    if [ ! -f "docs/book.toml" ]; then \
        @echo "❌ [docs]: No local documentation files found."; \
        @echo "   Run 'just docs-generate' first to create source files."; \
        exit 1; \
    fi
    @echo "📖 [docs]: Serving documentation at http://localhost:3000"
    @echo "   Press Ctrl+C to stop the server"
    cd docs && mdbook serve --open

docs:
    nix build .#docs
    @echo "[docs]: Documentation generated in result/"

clean:
    rm -rf result*
