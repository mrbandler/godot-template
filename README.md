# godot-template

A Godot 4.7 project template with GDScript, Rust (gdext) and C++ (godot-cpp + vcpkg), test-driven
from the first commit, with automated builds and releases to itch.io.

- GDScript, Rust and C++ side by side, each with a sample class, unit tests and engine tests.
- TDD: GdUnit4, `cargo test` and doctest, all behind one `just test`.
- Static typing enforced in `project.godot` (untyped and unsafe warnings are errors; `:=` is fine).
- Addons pinned and locked with [ggg](https://github.com/godotneers/ggg) (`ggg.toml`, `ggg.lock`).
- Reproducible dev environment with [devenv](https://devenv.sh) and direnv.
- Git hooks via prek: conventional commits, formatters, linters, tests before push.
- release-please versioning and changelog, per-OS exports pushed to itch.io with butler.

## Quick start

1. Click **Use this template** on GitHub.
2. In the clone: `direnv allow` (or `devenv shell`). This installs the tools, the git hooks and runs `ggg sync`.
3. `just test`
4. `ggg edit` (or `godot -e`) to open the editor.
5. Rename the game: `config/name` in `project.godot` and `application/bundle_identifier` in `export_presets.cfg`.

### Without Nix

Install [ggg](https://github.com/godotneers/ggg), [rustup](https://rustup.rs), CMake, Ninja and
Python 3, then:

```sh
ggg sync
cpp/vcpkg/bootstrap-vcpkg.sh
just build
```

Tests need devenv: `just test-gd` uses `$GODOT`, which only devenv sets.

## Layout

| Path | Content |
|---|---|
| `project.godot`, `export_presets.cfg` | Godot project at the repo root; Windows, Linux, macOS presets |
| `ggg.toml`, `ggg.lock` | Godot version, export templates, addons |
| `addons/` | Installed by `ggg sync`. Never edit. Three vendored addons are in git (see Addons) |
| `src/` | GDScript game code and main scene (sample: class `Health`) |
| `test/` | GdUnit4 tests; `test/rust/`, `test/cpp/` hold engine tests for the extensions |
| `extensions/<lang>/` | One `<name>.gdextension` per extension; built libraries in `bin/` (gitignored) |
| `rust/` | Cargo workspace, `crates/<name>` = one extension (sample: `health`, class `RustHealth`) |
| `cpp/` | CMake project with `godot-cpp` and `vcpkg` submodules; `extensions/<name>` = one extension (sample: `stamina`, class `CppStamina`) |
| `raw/` | Source assets (Blender, Aseprite, Krita, audio projects), stored via Git LFS; `.gdignore` hides it from Godot |
| `devenv.nix`, `justfile`, `.pre-commit-config.yaml` | Tooling |
| `.github/` | Workflows, dependabot, repo ruleset |

`rust/`, `cpp/` and `raw/` carry `.gdignore` so the editor skips build trees. `docs/` is local-only.

## Assets and Git LFS

Binary and raw assets (images, audio, video, fonts, 3D and paint sources, Godot binary resources)
are tracked with Git LFS; `.gitattributes` lists the formats. Text formats (`.tscn`, `.tres`,
`.gd`, `.svg`, `.gltf`) stay in plain git so they diff and merge.

- The devenv shell sets LFS up. Without Nix run `git lfs install` (Git for Windows ships git-lfs).
- Keep sources in `raw/` (Godot ignores it) and export game-ready files into the project tree.
- **Use this template** on GitHub does not copy LFS objects; the template ships none.
- Check GitHub's LFS storage and bandwidth limits before committing a lot of large assets.

## Included assets

[Kenney](https://kenney.nl) assets, CC0 (public domain), each pack keeps its `License.txt`.

| Path | Content | License |
|---|---|---|
| `assets/kenney/prototype_textures/` | Prototype Textures: 6 colours x 13 grid textures with a ready `texture_NN.tres` material each | CC0 |

Drag a `texture_NN.tres` onto a mesh, CSG or Cyclops block. The materials use world-space
triplanar mapping, so 1 grid cell = 1 m and neighbouring blocks line up.

## Testing

Each language has the same sample, a health value (damage, heal, clamp). Logic lives in code
without engine types; a thin Godot class wraps it.

| | Unit (no engine) | Engine (headless Godot) |
|---|---|---|
| GDScript | GdUnit4 `test/health_test.gd` | GdUnit4 scene runner `test/main_scene_test.gd` |
| Rust | `cargo test` in `rust/crates/health/src/health.rs` | `test/rust/health/rust_health_test.gd` on `RustHealth` |
| C++ | doctest via ctest, `cpp/extensions/stamina/tests/stamina_test.cpp` | `test/cpp/stamina/cpp_stamina_test.gd` on `CppStamina` |

```sh
just test        # everything
just test-rust   # cargo test
just test-cpp    # doctest via ctest
just test-gd     # builds the extensions, then GdUnit4
just check       # prek on all files, then just test (what CI runs)
```

### Git hooks

| Stage | What runs |
|---|---|
| commit-msg | Conventional commit check |
| pre-commit | Formatters in fix mode (commit stops, review the changes, `git add` again), linters (clippy, clang-tidy, gdscript lint, typos, zizmor) |
| pre-push | `just test` and `cargo shear` |

Commits to `main` are blocked; work on a branch.

## Addons

Managed by ggg and installed by `ggg sync`.

| Addon | Purpose | Source |
|---|---|---|
| GdUnit4 | Tests, mocks, scene runner | ggg, git tag |
| Phantom Camera | Camera follow, framing, transitions | ggg, git tag |
| LimboConsole | In-game dev console | ggg, release archive |
| G.U.I.D.E | Input contexts, rebinding, prompts | ggg, git tag |
| LimboAI | Behaviour trees and state machines (GDExtension) | ggg, release archive |
| YARD | Resource registries and table editor | ggg, git tag |
| Better Tooltips | Editor doc tooltips and previews | ggg, Asset Store |
| Cyclops Level Builder | In-editor level blockout and greyboxing | ggg, release archive |
| Broken Reference Finder, Todo Tracker, Unused Resource Finder | Editor audits (v1.1.0, kurtis-klay) | Godot Asset Store, vendored in git |

The last three are vendored because ggg 0.5.0 cannot parse their store entries
(`min_godot_version` is null). Update them by hand.

Add an addon:

```sh
ggg add git <url> --name <name>
ggg add asset-store publisher/slug
ggg sync
```

### Recommended per project

Not installed; add what the game needs.

| Plugin | Use |
|---|---|
| Dialogue Manager | Branching dialogue |
| Expose Them Properties | Inspector exposure of properties |
| GodotGAS | Gameplay ability system |

### Rejected

| Plugin | Reason |
|---|---|
| GUT | GdUnit4 covers it |
| Orchestrator | Not needed |
| Unibuilder | Proprietary |
| Asset Manager | GPL |
| Log.gd | Built-in `Logger` since Godot 4.5 |
| GATE | Not needed |

## C++ libraries

```sh
cd cpp && vcpkg add port <name>
```

Then `find_package(...)` in `cpp/CMakeLists.txt`. Pin the vcpkg baseline by updating the
`cpp/vcpkg` submodule.

## Extensions

Add one by copying a sample (`rust/crates/health` or `cpp/extensions/stamina`) together with its
`extensions/<lang>/<name>.gdextension` and `test/<lang>/<name>/`, then rename:

- the crate (Rust) or CMake target (C++), and the extension name,
- the entry symbol to `<name>_init`,
- the Godot class (`Rust...` / `Cpp...`).

Skip `.uid` files; Godot regenerates them. Names must be unique across Rust and C++: the library
file is the extension name and exports place all libraries flat next to the executable. Shared
Rust logic can live in plain rlib crates in the workspace.

Remove a language by deleting `<lang>/`, `extensions/<lang>/` and `test/<lang>/`. Every just
recipe and CI step skips itself when the folder is gone.

## Releasing

Setup, once per repository created from the template:

1. `just gh-setup` applies the `main` ruleset and squash-only merges (needs `gh auth login`).
2. Create the labels dependabot uses: `gh label create dependencies`, `gh label create rust`,
   `gh label create cpp`, `gh label create github-actions` (`gh-setup` does not).
3. **GitHub App** for release-please (create once per account, install on each repo). Actions run
   with the built-in `GITHUB_TOKEN`, and GitHub deliberately does not start other workflows from
   events that token causes. With it, CI would never run on the release PR (so the required
   checks never pass and it can't be merged) and the release tag would never trigger
   `release.yml`. A token from your own App does trigger workflows.
   - Settings, Developer settings, GitHub Apps, New GitHub App. No webhook needed.
     Repository permissions: *Contents* and *Pull requests* read/write.
   - Generate a private key, then install the App on this repo.
   - Add the secrets: `gh secret set APP_CLIENT_ID` (the App's Client ID) and
     `gh secret set APP_PRIVATE_KEY < key.pem`.
4. `just itch-setup <user> <game>` stores `BUTLER_API_KEY` (create a key at
   <https://itch.io/user/settings/api-keys>) and the `ITCH_USER` / `ITCH_GAME` variables.

Flow:

- Conventional commits on `main` keep a release PR open (`CHANGELOG.md`; `version.txt` is the only
  version). Merging it tags `vX.Y.Z`.
- `release.yml` builds on Ubuntu, Windows and macOS, runs the native unit tests, stamps the
  `project.godot` version from `version.txt`, exports and pushes with butler.
- Tags push the `windows`, `linux` and `macos` channels; pushes to `main` push `windows-dev`,
  `linux-dev` and `macos-dev`.
- The itch.io push is skipped when `ITCH_USER` / `ITCH_GAME` are unset. Nothing releases from the
  template repository itself.

Versioning: conventional commits drive the bump (`fix` is a patch, `feat` a minor, a breaking
change is a minor while below 1.0). Nobody edits versions by hand. To cut a specific version, e.g.
1.0.0, push an empty commit and release-please opens the PR for it:

```sh
git commit --allow-empty -m "chore: release 1.0.0" -m "Release-As: 1.0.0"
```

On itch.io, hide the `-dev` channels once. Whether new channels are public by default is
unverified: check the game's page after the first push.

macOS builds are universal (arm64 and x86_64) and ad-hoc signed, so on first launch use
right-click, Open.

## License

MIT. See `LICENSE`.
