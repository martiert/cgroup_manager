{
  description = "A system for automatically adding certain executables in a memory cgroup";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: 
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      packages.default = pkgs.stdenv.mkDerivation {
        name = "cgroup_monitor";
        version = "1.0.0";

        src = ./.;

        nativeBuildInputs = with pkgs; [
          gnumake
          clang

          libbpf
          libelf
          bpftools
          fmt.dev

          pkg-config
          which
        ];
      };
    });
}
