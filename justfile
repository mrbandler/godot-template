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
test-gd *ARGS="--headless --ignoreHeadlessMode": build import
    mkdir -p reports
    touch reports/.gdignore
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
    {{ if path_exists("rust") == "true" { "cargo test --manifest-path rust/Cargo.toml --workspace" } else { "echo 'no rust/, skipping'" } }}

# C++ unit tests (doctest via ctest, all extensions)
test-cpp:
    {{ if path_exists("cpp") == "true" { "cmake --preset debug -S cpp && cmake --build cpp/build/debug && ctest --test-dir cpp/build/debug --output-on-failure" } else { "echo 'no cpp/, skipping'" } }}

# Build every C++ extension into extensions/cpp/bin (profile: debug | release; release on macOS is universal)
[unix]
build-cpp profile="debug":
    #!/usr/bin/env bash
    set -euo pipefail
    [ -d cpp ] || exit 0
    out=extensions/cpp/bin
    mkdir -p "$out"
    exts=$(find cpp/extensions -mindepth 1 -maxdepth 1 -type d -exec basename {} \;)
    if [ "{{ os() }}" = macos ] && [ "{{ profile }}" = release ]; then
        for arch in arm64 x86_64; do
            triplet=$([ $arch = arm64 ] && echo arm64-osx || echo x64-osx)
            cmake --preset release -S cpp -B "cpp/build/release-$arch" \
                -DCMAKE_OSX_ARCHITECTURES=$arch -DVCPKG_TARGET_TRIPLET=$triplet
            cmake --build "cpp/build/release-$arch" --target $exts
        done
        for e in $exts; do
            lipo -create "cpp/build/release-arm64/extensions/$e/lib$e.dylib" \
                "cpp/build/release-x86_64/extensions/$e/lib$e.dylib" -output "$out/lib$e.dylib"
        done
    else
        cmake --preset {{ profile }} -S cpp
        cmake --build cpp/build/{{ profile }} --target $exts
        for e in $exts; do cp "cpp/build/{{ profile }}/extensions/$e/{{ lib_prefix }}$e.{{ lib_ext }}" "$out/"; done
    fi

[windows]
build-cpp profile="debug":
    if (Test-Path cpp) { \
      cmake --preset {{ profile }} -S cpp; \
      $exts = (Get-ChildItem cpp/extensions -Directory).Name; \
      cmake --build cpp/build/{{ profile }} --target $exts; \
      New-Item -ItemType Directory -Force extensions/cpp/bin | Out-Null; \
      foreach ($e in $exts) { Copy-Item "cpp/build/{{ profile }}/extensions/$e/$e.dll" extensions/cpp/bin/ } \
    }

# Build all extensions
build profile="debug": (build-rust profile) (build-cpp profile)

# Format all code
fmt:
    -gdscript-formatter $(git ls-files '*.gd' ':!addons')
    {{ if path_exists("rust") == "true" { "cargo fmt --manifest-path rust/Cargo.toml --all" } else { "" } }}
    {{ if path_exists("cpp") == "true" { "clang-format -i cpp/extensions/*/src/* cpp/extensions/*/tests/*" } else { "" } }}

# Run all pre-commit hooks on every file
lint:
    prek run --all-files

# All tests: Rust, C++, then GDScript + engine tests
test: test-rust test-cpp test-gd

# Everything CI runs
check: lint test

# Apply repo ruleset and merge settings (needs a GitHub remote and gh auth)
gh-setup:
    gh api --method POST "repos/{owner}/{repo}/rulesets" --input .github/rulesets/main.json
    gh api --method PATCH "repos/{owner}/{repo}" -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY

# Export a preset (Linux | Windows | macOS) to build/<preset>/ with release libraries
[unix]
export preset: (build "release") import
    mkdir -p build/{{ preset }}
    touch build/.gdignore
    {{ godot }} --headless --export-release "{{ preset }}"

[windows]
export preset: (build "release") import
    New-Item -ItemType Directory -Force build/{{ preset }} | Out-Null; New-Item -ItemType File -Force build/.gdignore | Out-Null; {{ godot }} --headless --export-release "{{ preset }}"

# One-shot setup right after "Use this template" + clone: LFS and labels. Safe to re-run. Never pushes.
[unix]
init:
    #!/usr/bin/env bash
    set -euo pipefail
    gh auth status >/dev/null 2>&1 || { echo "gh is not logged in: run 'gh auth login' first" >&2; exit 1; }
    git remote get-url origin >/dev/null 2>&1 || { echo "no 'origin' remote: create the repo from the template and clone it first" >&2; exit 1; }

    if grep -q '^# lfs-template:start' .gitattributes; then
        just lfs-adopt
        # The setup commit lands on main before the ruleset and feature-branch flow exist.
        SKIP=no-commit-to-branch git commit -m "build: move Kenney assets into Git LFS"
    else
        echo "Kenney assets already in LFS, skipping"
    fi

    # Labels dependabot applies (dependabot.yml `labels: [a, b]` lines)
    grep -h 'labels:' .github/dependabot.yml | sed 's/.*\[\(.*\)\].*/\1/' | tr ',' '\n' | tr -d ' ' | sort -u \
        | while read -r label; do gh label create "$label" --force; done

    cat <<'EOF'

    Done. Next steps, in order:
      1. git push (puts the setup commit on main)
      2. just gh-setup (ruleset and merge settings; run once, after the push)
      3. Create the GitHub App and set APP_CLIENT_ID / APP_PRIVATE_KEY (README, Releasing, step 2)
      4. just itch-setup <user> <game>
      5. Rename the game: config/name in project.godot, application/bundle_identifier in export_presets.cfg
    EOF

# One-shot: move the Kenney packs into Git LFS (the template ships them as plain git)
[unix]
lfs-adopt:
    sed -i.bak '/^# lfs-template:start/,/^# lfs-template:end/d' .gitattributes && rm .gitattributes.bak
    awk 'NF{for(;n>0;n--)print "";print;next}{n++}' .gitattributes > .gitattributes.new && mv .gitattributes.new .gitattributes
    git add .gitattributes && git add --renormalize assets/kenney
    @echo "now commit: git commit -m 'build: move Kenney assets into Git LFS'"

# Store itch.io credentials for the release workflow (needs gh). Create a key at https://itch.io/user/settings/api-keys
itch-setup user game:
    gh secret set BUTLER_API_KEY
    gh variable set ITCH_USER --body "{{ user }}"
    gh variable set ITCH_GAME --body "{{ game }}"
