set windows-shell := ["pwsh", "-NoLogo", "-NoProfile", "-Command"]

# Godot binary: devenv sets GODOT; without Nix, ggg runs the pinned engine.
godot := env("GODOT", "ggg run")

# List recipes
default:
    @just --list

# Import the project headless (class cache, extension list)
import:
    {{ godot }} --headless --editor --quit-after 300

# GDScript tests (GdUnit4). Extra args go to Godot, e.g. display flags under xvfb.
test-gd *ARGS="--headless --ignoreHeadlessMode": build-rust import
    bash addons/gdUnit4/runtest.sh --godot_binary "$GODOT" -a res://test -c -rd reports {{ ARGS }}

lib_ext := if os() == "macos" { "dylib" } else if os() == "windows" { "dll" } else { "so" }
lib_prefix := if os() == "windows" { "" } else { "lib" }

# Build every Rust extension (cdylib crate) into extensions/rust/bin (profile: debug | release; release on macOS is universal)
[unix]
build-rust profile="debug":
    #!/usr/bin/env bash
    set -euo pipefail
    [ -d rust ] || exit 0
    m=rust/Cargo.toml
    out=extensions/rust/bin
    mkdir -p "$out"
    flag=$([ "{{ profile }}" = release ] && echo --release || true)
    exts=$(cargo metadata --manifest-path $m --no-deps --format-version 1 \
        | jq -r '.packages[].targets[] | select(.crate_types | index("cdylib")) | .name')
    if [ "{{ os() }}" = macos ] && [ "{{ profile }}" = release ]; then
        rustup target add aarch64-apple-darwin x86_64-apple-darwin
        cargo build --manifest-path $m --workspace $flag --target aarch64-apple-darwin
        cargo build --manifest-path $m --workspace $flag --target x86_64-apple-darwin
        for e in $exts; do
            lipo -create rust/target/{aarch64,x86_64}-apple-darwin/release/lib$e.dylib -output "$out/lib$e.dylib"
        done
    else
        cargo build --manifest-path $m --workspace $flag
        for e in $exts; do cp "rust/target/{{ profile }}/{{ lib_prefix }}$e.{{ lib_ext }}" "$out/"; done
    fi

[windows]
build-rust profile="debug":
    if (Test-Path rust) { \
      cargo build --manifest-path rust/Cargo.toml --workspace $(if ("{{ profile }}" -eq "release") { "--release" }); \
      New-Item -ItemType Directory -Force extensions/rust/bin | Out-Null; \
      $meta = cargo metadata --manifest-path rust/Cargo.toml --no-deps --format-version 1 | ConvertFrom-Json; \
      $meta.packages.targets | Where-Object { $_.crate_types -contains "cdylib" } | ForEach-Object { Copy-Item "rust/target/{{ profile }}/$($_.name).dll" extensions/rust/bin/ } \
    }

# Rust unit tests (all crates)
test-rust:
    {{ if path_exists("rust") == "true" { "cargo test --manifest-path rust/Cargo.toml --workspace" } else { "@echo 'no rust/, skipping'" } }}
