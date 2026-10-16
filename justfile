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
test-gd *ARGS="--headless --ignoreHeadlessMode": import
    bash addons/gdUnit4/runtest.sh --godot_binary "$GODOT" -a res://test -c -rd reports {{ ARGS }}
