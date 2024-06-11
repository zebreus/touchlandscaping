{
  description = "Xtreme Touchlandscaping deluxe++";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        name = "touchlandscaping";

        devShell = pkgs.mkShell {
          buildInputs = [
            (pkgs.processing3)
            # pkgs.mesa
            pkgs.libGL
            # pkgs.gvfs
            # pkgs.udev
            pkgs.xorg.libX11
            pkgs.xorg.libXrandr
            pkgs.xorg.libXcursor
            pkgs.xorg.libXi
            pkgs.xorg.libXt
            # pkgs.xorg.libXxf86vm
            pkgs.xorg.libXrender
            # pkgs.mesa
            # pkgs.jogl
          ];
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath (
            with pkgs;
            [
              # freeglut
              libGL
              # gvfs
              # udev
              xorg.libX11
              xorg.libXrandr
              xorg.libXcursor
              xorg.libXi
              xorg.libXt
              # xorg.libXxf86vm
              xorg.libXrender
              # mesa
              # jogl
            ]
          );
        };
      }
    );
}
