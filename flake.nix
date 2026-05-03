{
  description = "mcp-cli packaged for NixOS on Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      packageJson = builtins.fromJSON (builtins.readFile ./package.json);

      forEachSystem = nixpkgs.lib.genAttrs systems;

      packageFor =
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          buildScript =
            {
              aarch64-linux = "build:linux-arm";
              x86_64-linux = "build:linux";
            }
            .${system};
          binaryName =
            {
              aarch64-linux = "mcp-cli-linux-arm64";
              x86_64-linux = "mcp-cli-linux-x64";
            }
            .${system};

          node_modules = pkgs.stdenvNoCC.mkDerivation {
            pname = "${packageJson.name}-node_modules";
            version = packageJson.version;
            src = ./.;

            impureEnvVars = pkgs.lib.fetchers.proxyImpureEnvVars ++ [
              "GIT_PROXY_COMMAND"
              "SOCKS_SERVER"
            ];

            nativeBuildInputs = [
              pkgs.bun
            ];

            dontConfigure = true;

            buildPhase = ''
              runHook preBuild

              export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
              bun install --cpu="*" --os="*" --no-progress --frozen-lockfile

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out
              cp -R node_modules $out/

              runHook postInstall
            '';

            dontFixup = true;
            outputHash = "sha256-NTBDHiBAoOJaxFC4iaqYTfwpA5JRV86TkHY/klSGW0w=";
            outputHashAlgo = "sha256";
            outputHashMode = "recursive";
          };
        in
        pkgs.stdenvNoCC.mkDerivation {
          pname = packageJson.name;
          version = packageJson.version;
          src = ./.;

          nativeBuildInputs = [
            pkgs.bun
          ];

          dontConfigure = true;

          buildPhase = ''
            runHook preBuild

            cp -R ${node_modules}/node_modules .
            chmod -R u+w node_modules
            bun run ${buildScript}

            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 dist/${binaryName} $out/bin/mcp-cli

            runHook postInstall
          '';

          meta = {
            description = packageJson.description;
            homepage = packageJson.homepage;
            license = pkgs.lib.licenses.mit;
            mainProgram = "mcp-cli";
            platforms = [ system ];
          };
        };
    in
    {
      packages = forEachSystem (
        system:
        let
          mcp-cli = packageFor system;
        in
        {
          default = mcp-cli;
          mcp-cli = mcp-cli;
        }
      );
    };
}
