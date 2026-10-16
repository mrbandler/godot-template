{ pkgs, lib, ... }:
let
  # ggg.toml is the single source for the Godot version.
  gggConfig = builtins.fromTOML (builtins.readFile ./ggg.toml);
  godot = pkgs.godot_4_7;
  godotBin = lib.getExe godot;

  # Built from source so it runs on NixOS (release binaries are generic glibc builds).
  ggg = pkgs.rustPlatform.buildRustPackage rec {
    pname = "ggg";
    version = "0.5.0";
    src = pkgs.fetchFromGitHub {
      owner = "godotneers";
      repo = "ggg";
      rev = "v${version}";
      hash = "sha256-UgCHh3uj53ZI7eWH1KIhWW1hLC5eWF0i2wYbQLRUiJk=";
    };
    cargoHash = "sha256-loJPh3r0xq68Pf0XmO8zIOD7r6CforDa5QdHLCSMg9I=";
    doCheck = false; # upstream tests need network mocks
  };
in
{
  assertions = [
    {
      assertion = godot.version == gggConfig.project.godot;
      message = "nixpkgs Godot is ${godot.version} but ggg.toml pins ${gggConfig.project.godot}. Update nixpkgs (devenv update) or ggg.toml.";
    }
  ];

  languages.rust = {
    enable = true;
    toolchainFile = ./rust-toolchain.toml;
  };

  packages = with pkgs; [
    godot
    ggg
    just
    prek
    typos
    zizmor
    cargo-shear
    jq
    gh
    butler
    gdscript-formatter
    cmake
    ninja
    python3 # godot-cpp binding generator
    vcpkg-tool
    clang-tools # clang-format
  ] ++ lib.optionals stdenv.isLinux [ xvfb-run ];

  env = {
    GODOT = godotBin;
    GGG_GODOT_EXECUTABLE = godotBin;
    VCPKG_ROOT = "./cpp/vcpkg";
    VCPKG_FORCE_SYSTEM_BINARIES = "1"; # use Nix cmake/ninja, not vcpkg downloads
    RUST_BACKTRACE = "1";
  };

  enterShell = ''
    prek install
    ggg sync
  '';
}
