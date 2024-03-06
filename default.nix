{ pkgs, pkgRuby, gems, lib, manifest, ... }: (
  let
    name                                                         = manifest.name;
    dependencies                                                 = with pkgs; [
      imagemagick        # /bin/convert
      ffmpeg             # /bin/ffmpeg
    ];
  in (
    pkgs.stdenv.mkDerivation {
      inherit name;

      src                          = lib.cleanSource ./.;

      nativeBuildInputs = with pkgs; [
        makeWrapper
        bash
        pkgRuby
      ] ++ [ gems ] ++ dependencies;

      buildPhase = ''
        mkdir -p $out/{bin,share/$name}
        cp -r * $out/share/$name

        bin=$out/bin/$name
        cat > $bin <<EOF
          #!${pkgs.bash}/bin/bash

          exec ${gems}/bin/bundle exec ${pkgRuby}/bin/ruby $out/share/$name/bin/$name "\$@"
        EOF
        chmod +x $bin
      '';

      postBuild = ''
        wrapProgram $out/bin/$name --set PATH ${lib.makeBinPath (dependencies)}
      '';
    }
  )
)
