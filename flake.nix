{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        icon = pkgs.fetchurl {
          url = "https://avatars.githubusercontent.com/u/91479705?s=200&v=4";
          sha256 = "QdqLYzJ47tmXX1PtwhE3XHnPm5l52DzyVlVobIJT8ZI=";
        };
        generations = 400;
      in
      {
        packages = rec {
          wishy = pkgs.runCommand "wishy-output"
            {
              buildInputs = [ pkgs.tree pkgs.imagemagick pkgs.potrace ];
            }
            ''
              mkdir -p $out
              cp ${icon} icon.png
              convert icon.{png,bmp}
              for i in $(seq -f "%03g" 0 ${builtins.toString generations}) ; do
                echo generation $i
                cp icon.bmp $out/$i.bmp
                potrace icon.bmp --svg
                convert icon.svg -resize 200x200 icon.bmp
              done
            '';
          display = pkgs.writeShellScriptBin "display" ''
            ${pkgs.nomacs}/bin/nomacs ${wishy}
          '';
        };
        apps = {
          default = flake-utils.lib.mkApp {
            drv = self.packages.${system}.display;
          };
        };
      }
    );
}
