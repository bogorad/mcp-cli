# mcp-cli on NixOS

This repository provides a Nix flake for easy installation and usage of `mcp-cli` on NixOS and other systems with Nix installed.

## Usage

### Ad-hoc Usage (`nix run`)

You can run `mcp-cli` directly without installing it:

```bash
nix run github:bogorad/mcp-cli --refresh
```

This ensures you are always using the latest version.

### Including in Your Flake

To use `mcp-cli` in your own system configuration or development flake, add it to your `inputs`:

```nix
{
  inputs = {
    # ... other inputs
    mcp-cli.url = "github:bogorad/mcp-cli";
  };

  outputs = { self, nixpkgs, mcp-cli, ... }: {
    # Using it in your package list or devShell
    
    # Method 1: Access the package directly
    packages.x86_64-linux.default = mcp-cli.packages.x86_64-linux.default;

    # Method 2: Usage in a devShell (e.g., inside mkShell)
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [
        # ... other packages
        mcp-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
```

### Development Shell

To use the development environment provided by this flake (which includes Bun, Biome, and TypeScript):

```nix
{
  inputs = {
    mcp-cli.url = "github:bogorad/mcp-cli";
  };

  outputs = { self, nixpkgs, mcp-cli, ... }: {
    devShells.x86_64-linux.default = mcp-cli.devShells.x86_64-linux.default;
  };
}
```

### Installation Profile (Non-Flake)

If you are using `nix profile`:

```bash
nix profile install github:bogorad/mcp-cli
```

## Features

- **Automated Updates**: This flake automatically checks the upstream repository for new releases every hour.
- **Reproducible Builds**: Dependency hashes are strictly pinned and verified via GitHub Actions build matrix.
- **Multi-Arch Support**: Pre-calculated hashes are available for:
  - `x86_64-linux`
  - `aarch64-linux`

## Development

To enter a development environment with all dependencies (Bun, Biome, TypeScript) pre-configured:

```bash
nix develop
```

This will drop you into a shell where you can run `bun run dev` or the aliased `mcp-cli-dev` command.
