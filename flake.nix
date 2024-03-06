{
  description                                       = "lolcommits";

  inputs                                            = {
    nixpkgs.url                                     = "github:NixOS/nixpkgs/23.11";

    flake-utils.url                                 = "github:numtide/flake-utils";

    task-runner.url                                 = "git+ssh://git@gitlab.com/ox_os/package_task_runner?rev=e9c739f3d983acd133a7e9cc43e9940acdf2318f";
  };

  outputs                                           = {
    nixpkgs,
    flake-utils,
    ...
  }@inputs:
    let
      systems                                                    = ["x86_64-linux"];

      mkPkgs                                                     = system:
        pkgs: (
          # NixPkgs
          import pkgs { inherit system; }
          //
          # Custom Packages.
          { }
        );
    in (
      flake-utils.lib.eachSystem systems (system: (
        let
          pkgs                                      = mkPkgs system nixpkgs;
          pkgRuby                                   = pkgs.ruby;
          gems                                      = pkgs.bundlerEnv {
            name = "lolcommits-env";
            ruby = pkgRuby;
            gemdir  = ./.;
            copyGemFiles = true;
          };

          manifest                                  = (pkgs.lib.importTOML ./package.toml);
          environment                               = {
            inherit system;
            inherit pkgs;
            inherit pkgRuby;
            inherit gems;
            inherit manifest;
          };
          name                                      = manifest.name;

          package                                   = pkgs.callPackage ./default.nix environment;
          application                               = flake-utils.lib.mkApp {
            inherit name;
            drv                                     = package;
          };
        in {
          packages.${name}                          = package;
          apps.${name}                              = application;

          # `nix build`
          defaultPackage                            = package;

          # `nix run`
          defaultApp                                = application;

          # `nix develop`
          devShells.default                      = import ./shell/default.nix {
            inherit mkPkgs system;
            flake-inputs                         = inputs;
          };
        }
      )
    )
  );
}

