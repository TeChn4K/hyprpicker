{
  description = "Hyprpicker - a wlroots-compatible Wayland color picker that does not suck";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    inherit (nixpkgs) lib;
    genSystems = lib.genAttrs [
      # Add more systems if they are supported
      "aarch64-linux"
      "x86_64-linux"
    ];
    pkgsFor = nixpkgs.legacyPackages;
    mkDate = longDate: (lib.concatStringsSep "-" [
      (builtins.substring 0 4 longDate)
      (builtins.substring 4 2 longDate)
      (builtins.substring 6 2 longDate)
    ]);
    version = lib.removeSuffix "\n" (builtins.readFile ./VERSION);
  in {
    overlays.default = _: prev: rec {
      hyprpicker = prev.callPackage ./nix/default.nix {
        stdenv = prev.gcc12Stdenv;
        version = version + "+date=" + (mkDate (self.lastModifiedDate or "19700101")) + "_" + (self.shortRev or "dirty");
        wayland-protocols = prev.wayland-protocols.overrideAttrs (self: super: {
          version = "1.34";
          src = prev.fetchurl {
            url = "https://gitlab.freedesktop.org/wayland/${self.pname}/-/releases/${self.version}/downloads/${self.pname}-${self.version}.tar.xz";
            hash = "sha256-xZsnys2F9guvTuX4DfXA0Vdg6taiQysAq34uBXTcr+s=";
          };
        });
        inherit (prev.xorg) libXdmcp;
      };
      hyprpicker-debug = hyprpicker.override {debug = true;};
    };

    packages = genSystems (system:
      (self.overlays.default null pkgsFor.${system})
      // {default = self.packages.${system}.hyprpicker;});

    formatter = genSystems (system: pkgsFor.${system}.alejandra);
  };
}
