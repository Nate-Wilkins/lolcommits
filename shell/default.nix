{ mkPkgs, flake-inputs, system, ... }: (
  let
    pkgs                                                        = mkPkgs system flake-inputs.nixpkgs;
    taskRunner                                                  =
      flake-inputs.task-runner.taskRunner.${system};

    #
    # Run help.
    #
    task_help                                           = taskRunner.mkTask {
      name                                              = "help";
      dependencies                                      = with pkgs; [
        coreutils           # /bin/echo
      ];
      src                                               = with pkgs; ''
        ${coreutils}/bin/echo "                                                                     "
        ${coreutils}/bin/echo "Usage                                                                "
        ${coreutils}/bin/echo "   clean                  Run cleanup on temporary files.            "
        ${coreutils}/bin/echo "   build                  Run build procedure for specific build.    "
        ${coreutils}/bin/echo "   show                   Run show info for the flake.               "
        ${coreutils}/bin/echo "   run                    Run the project.                           "
        ${coreutils}/bin/echo "   help                   Run help.                                  "
        ${coreutils}/bin/echo "                                                                     "
      '';
    };

    #
    # Run cleanup on ignored files.
    #
    task_clean                                                = taskRunner.mkTask {
      name                                                    = "clean";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        findutils           # /bin/find  /bin/xargs
        git                 # /bin/git
      ];
      isolate                                                 = false;
      src                                                     = with pkgs; ''
        # Delete all ignored files.
        ${git}/bin/git ls-files -o --ignored --exclude-standard | ${findutils}/bin/xargs rm -rf

        # Delete all empty directories.
        ${findutils}/bin/find . -type d -empty -delete
      '';
    };

    #
    # Run build procedure for specific build.
    #
    task_build                                                = taskRunner.mkTask {
      name                                                    = "build";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        nix                 # /bin/nix
          git               # /bin/git
      ];
      src                                                     = with pkgs; ''
        ${nix}/bin/nix build \
          --experimental-features 'nix-command flakes' \
          --show-trace \
          --verbose \
          --option eval-cache false \
          -L \
          "."
      '';
    };

    #
    # Run show info for the flake.
    #
    task_show                                                 = taskRunner.mkTask {
      name                                                    = "show";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        findutils           # /bin/find
        nix                 # /bin/nix
          git               # /bin/git
      ];
      src                                                     = with pkgs; ''
        ${nix}/bin/nix flake show \
          --experimental-features 'nix-command flakes'
      '';
    };

    #
    # Run the project.
    #
    task_run                                                  = taskRunner.mkTask {
      name                                                    = "run";
      dependencies                                            = with pkgs; [
        coreutils           # /bin/echo
        nix                 # /bin/nix
          git               # /bin/git
      ];
      isolate                                                 = false;
      src                                                     = with pkgs; ''
        ${nix}/bin/nix run \
          --experimental-features 'nix-command flakes' \
          --show-trace \
          --verbose \
          --option eval-cache false \
          -L \
          "." -- $@
      '';
    };
  in (
    taskRunner.mkTaskRunner {
      tasks                                              = {
        help                                             = task_help;
        clean                                            = task_clean;
        build                                            = task_build;
        show                                             = task_show;
        run                                              = task_run;
      };
    }
  )
)
