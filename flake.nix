{
  description = "A lightweight CLI for interacting with MCP (Model Context Protocol) servers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        metadata = builtins.fromJSON (builtins.readFile ./metadata.json);
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "mcp-cli";
          version = metadata.version;
          src = ./.;

          nativeBuildInputs = [
            pkgs.bun
            pkgs.makeBinaryWrapper
          ];

          # Fixed-output derivation to fetch dependencies
          # Using a dummy hash first to get the correct one from Nix
          passthru.deps = pkgs.stdenv.mkDerivation {
            pname = "mcp-cli-deps";
            version = metadata.version;
            src = ./.;
            nativeBuildInputs = [ pkgs.bun ];
            buildPhase = ''
              export HOME=$TMPDIR
              bun install --frozen-lockfile
            '';
            installPhase = ''
              mkdir -p $out
              cp -r node_modules $out/
            '';
            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
            outputHash = metadata.hashes.${system};
          };

          buildPhase = ''
            export HOME=$TMPDIR
            ln -s ${self.packages.${system}.default.passthru.deps}/node_modules .

            # Bundle instead of compile for better Nix compatibility
            bun build src/index.ts --outfile dist/index.js --target bun
          '';

          installPhase = ''
            mkdir -p $out/libexec/mcp-cli $out/bin

            # Install the bundled script
            cp dist/index.js $out/libexec/mcp-cli/index.js

            # Create a wrapper
            makeWrapper ${pkgs.bun}/bin/bun $out/bin/mcp-cli \
              --add-flags "run $out/libexec/mcp-cli/index.js"
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            bun
            nodejs_24
            typescript
            biome
          ];

          shell = "${pkgs.zsh}/bin/zsh";

          shellHook = ''
            echo "--- MCP-CLI Development Environment ---"
            echo "Available tools: bun, tsc, biome"
            node --version | sed 's/^/Node version: /'
            bun --version | sed 's/^/Bun version: /'

            # Alias for local development
            alias mcp-cli-dev="bun run src/index.ts"
            export MCP_CONFIG_PATH=$HOME/.dotfiles/mcp/mcp.json
          '';
        };
      }
    );
}
