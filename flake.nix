{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: 
      let 
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        formatter = pkgs.alejandra;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zls
            zig
          ];
        };
      }
    );
}
