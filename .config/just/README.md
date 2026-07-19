# just/ Script Directory

- `platform.sh`
  - Detects the current platform (`darwin`/`linux`/`termux`). The `justfile` uses this to select platform-specific recipe suffixes.

- `common.sh`
  - Provides `collect_recipes`, which parses `just --list` output and returns recipes following the `<primary>-<domain>-<name>[-<os>]` naming convention.

- `list.sh`
  - Implements `just list`. Supports filtering by primary category, domain, platform, and name. Can emit raw output (`raw=1`) for pipelines.

- `install.sh`
  - Resolves package names to available recipes, selects the current-platform variant, and runs the install recipe.

- `install_menu.sh`
  - Provides interactive multi-select installation based on `list.sh` output. Uses `fzf` when available and falls back to manual input.

- `asdf_install_menu.sh`
  - Provides interactive asdf version management. Uses `fzf` to select versions for configured plugins and optionally set home-level defaults.

The `justfile` defines entry points; reusable parsing, selection, and install logic lives in this directory.
