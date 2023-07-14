{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        original = pkgs.fetchurl {
          name = "image.png";
          url = "https://avatars.githubusercontent.com/u/91479705?s=200&v=4";
          sha256 = "QdqLYzJ47tmXX1PtwhE3XHnPm5l52DzyVlVobIJT8ZI=";
        };
        mkImage = generation:
          pkgs.runCommand "image-${builtins.toString generation}.bmp"
            {
              buildInputs = with pkgs; [ potrace imagemagick ];
            }
            (if generation > 0
            then
              ''
                echo running generation ${builtins.toString generation}
                potrace ${mkImage (generation - 1)} --svg --output tmp.svg
                convert tmp.svg -resize 200x200 $out
              ''
            else
              ''
                echo converting original image to bmp
                convert ${original} -resize 200x200 $out
              '');
        collectImages = generation:
          pkgs.runCommand "collectImages-${builtins.toString generation}"
            {
              env = {
                images = builtins.toString (builtins.genList mkImage generation);
              };
            }
            ''
              echo collecting links...
              mkdir -p $out
              cd $out
              i=0
              for image in $images ; do
                ln -s $image $(printf "%03g" $i).bmp
                i=$(($i + 1))
              done
            ''
        ;
      in
      {
        packages = {
          images = collectImages 300;
          default = pkgs.writeShellScriptBin "wishy" ''
            ${pkgs.nomacs}/bin/nomacs ${self.packages.${system}.images}
          '';
        };
        apps.default = flake-utils.lib.mkApp {
          drv = self.packages.${system}.default;
        };
      });
}
