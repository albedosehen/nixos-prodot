# Documentation Workflow

I've set up this directory to contain the source files for the NixOS configuration documentation. You can now edit these files locally and build the documentation from them - I don't know how convenient this will end up being so YMMV.

## Quick Start

1. **Generate source files** Will create the source documentation template. Shouldn't need to be ran unless you are re-generating your own documentation.

   ```bash
   just docs-generate
   ```

2. **Edit documentation**: Modify files in `docs/src/` 

3. **Build HTML documentation**:

   ```bash
   just docs-build
   ```

4. **Start development server** (for live editing):
   ```bash
   just docs-serve
   ```

## Available Commands

| Command              | Description                                                     |
| -------------------- | --------------------------------------------------------------- |
| `just docs-generate` | Generate documentation source files locally                     |
| `just docs-build`    | Build HTML docs from local source files                         |
| `just docs-serve`    | Start local documentation server at http://localhost:3000       |
| `just docs`          | Generate documentation using original Nix build (profile-aware) |

## File Structure

```
docs/
├── book.toml           # mdBook configuration
├── src/                # Markdown source files
│   ├── SUMMARY.md      # Table of contents
│   ├── introduction.md # Introduction page
│   ├── profiles.md     # Profile overview
│   ├── installation.md # Installation guide
│   ├── configuration.md # Configuration guide
│   ├── switching.md    # Profile switching guide
│   ├── git-management.md # Git profile management
│   ├── modules.md      # Modules reference
│   ├── development.md  # Development guide
│   ├── testing.md      # Testing guide
│   └── contributing.md # Contributing guide
└── README.md           # This file
```

## Workflow

### For Documentation Editing

Here's how I recommend working with the documentation:

1. **Initial setup**: Run `just docs-generate` to create the base documentation files
2. **Edit content**: Modify the markdown files in `docs/src/` to customize your documentation
3. **Preview changes**: Use `just docs-serve` to start a live development server
4. **Build final docs**: Use `just docs-build` to create the final HTML output

### For Profile-Aware Documentation

I've kept the original `just docs` command working - it generates documentation that includes current profile information. This is useful for:

- Generating documentation that reflects your current system configuration
- Including profile-specific capability information
- Creating documentation for distribution

## Customization

I've made it easy to customize the documentation to your needs.

### Adding New Pages

1. Create a new `.md` file in `docs/src/`
2. Add it to the table of contents in `docs/src/SUMMARY.md`
3. Build or serve to see your changes

### Modifying Configuration

You can edit `docs/book.toml` to customize:

- Book title and authors
- Theme settings
- Output options
- Plugin configuration

### Updating Content

The generated files are templates that you can freely modify:

- Edit any markdown file to customize content
- Add new sections or pages
- Modify the structure in `SUMMARY.md`
- Update styling through `book.toml`

## Integration with Nix

I've set up two different build approaches:

- **Local build**: `just docs-build` uses the `docs-local` Nix package
- **Profile-aware build**: `just docs` uses the original `docs` Nix package
- **Development**: `just docs-serve` uses mdbook directly for fast iteration

I designed the local workflow for documentation editing and development, while the Nix build provides reproducible, profile-aware documentation generation.
