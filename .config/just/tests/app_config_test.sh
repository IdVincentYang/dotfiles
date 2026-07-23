#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_CONFIG="$REPO_ROOT/just/app_config.sh"
RESTORE_HELPER="$REPO_ROOT/just/app_config_restore_if_enabled.sh"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_file_content() {
    local path="$1"
    local expected="$2"
    [[ -f "$path" ]] || fail "missing file: $path"
    local actual
    actual="$(<"$path")"
    [[ "$actual" == "$expected" ]] || fail "unexpected content for $path: $actual"
}

assert_not_exists() {
    local path="$1"
    [[ ! -e "$path" ]] || fail "path should not exist: $path"
}

new_home() {
    local tmp
    tmp="$(mktemp -d "${TMPDIR:-/tmp}/app-config-test.XXXXXX")"
    mkdir -p "$tmp/home"
    printf '%s\n' "$tmp/home"
}

test_backup_skips_when_all_sources_missing_without_removing_old_backup() {
    local home
    home="$(new_home)"
    local backup_root="$home/.config/backups/macos/Application Support/TestApp"
    mkdir -p "$backup_root"
    printf 'old' > "$backup_root/old.ini"

    HOME="$home" "$APP_CONFIG" backup "Application Support/TestApp" "missing.ini"

    assert_file_content "$backup_root/old.ini" "old"
}

test_backup_replaces_existing_backup_root_with_current_snapshot() {
    local home
    home="$(new_home)"
    local source_root="$home/Library/Application Support/TestApp"
    local backup_root="$home/.config/backups/macos/Application Support/TestApp"
    mkdir -p "$source_root" "$backup_root"
    printf 'new-a' > "$source_root/a.ini"
    printf 'old-a' > "$backup_root/a.ini"
    printf 'old-b' > "$backup_root/b.ini"
    printf 'keep gitignore' > "$backup_root/.gitignore"

    HOME="$home" "$APP_CONFIG" backup "Application Support/TestApp" "a.ini" "b.ini"

    assert_file_content "$backup_root/a.ini" "new-a"
    assert_not_exists "$backup_root/b.ini"
    assert_file_content "$backup_root/.gitignore" "keep gitignore"
}

test_backup_with_custom_backup_root_does_not_replace_sibling_preference_backups() {
    local home
    home="$(new_home)"
    local source_root="$home/Library/Preferences"
    local preference_backup_root="$home/.config/backups/macos/Preferences"
    local input_backup_root="$preference_backup_root/input-sources"
    mkdir -p "$source_root" "$preference_backup_root" "$input_backup_root"
    printf 'source-input' > "$source_root/input.plist"
    printf 'old-input' > "$input_backup_root/input.plist"
    printf 'existing-trackpad' > "$preference_backup_root/trackpad.plist"

    HOME="$home" "$APP_CONFIG" backup --backup-root "Preferences/input-sources" "Preferences" "input.plist"

    assert_file_content "$input_backup_root/input.plist" "source-input"
    assert_file_content "$preference_backup_root/trackpad.plist" "existing-trackpad"
}

test_restore_skips_when_all_backups_missing_without_touching_target() {
    local home
    home="$(new_home)"
    local target_root="$home/Library/Application Support/TestApp"
    mkdir -p "$target_root"
    printf 'local' > "$target_root/a.ini"

    HOME="$home" "$APP_CONFIG" restore "Application Support/TestApp" "a.ini"

    assert_file_content "$target_root/a.ini" "local"
}

test_restore_applies_snapshot_for_managed_paths_only() {
    local home
    home="$(new_home)"
    local target_root="$home/Library/Application Support/TestApp"
    local backup_root="$home/.config/backups/macos/Application Support/TestApp"
    mkdir -p "$target_root" "$backup_root"
    printf 'backup-a' > "$backup_root/a.ini"
    printf 'target-a' > "$target_root/a.ini"
    printf 'target-b' > "$target_root/b.ini"
    printf 'target-unmanaged' > "$target_root/unmanaged.ini"

    HOME="$home" "$APP_CONFIG" restore "Application Support/TestApp" "a.ini" "b.ini"

    assert_file_content "$target_root/a.ini" "backup-a"
    assert_not_exists "$target_root/b.ini"
    assert_file_content "$target_root/unmanaged.ini" "target-unmanaged"

    local before_count
    before_count="$(find "$home/Library/Application Support" -maxdepth 1 -type d -name 'TestApp.before-dotfiles-*' | wc -l | tr -d ' ')"
    [[ "$before_count" == "1" ]] || fail "expected one before-dotfiles backup, got $before_count"
}

test_restore_helper_only_runs_when_enabled() {
    local home
    home="$(new_home)"
    local marker="$home/marker"
    local recipe_script="$home/recipe.sh"
    cat > "$recipe_script" <<SCRIPT
#!/usr/bin/env bash
printf ran > "$marker"
SCRIPT
    chmod +x "$recipe_script"

    HOME="$home" "$RESTORE_HELPER" "$recipe_script"
    assert_not_exists "$marker"

    DOTFILES_RESTORE_APP_CONFIG=1 HOME="$home" "$RESTORE_HELPER" "$recipe_script"
    assert_file_content "$marker" "ran"
}

main() {
    test_backup_skips_when_all_sources_missing_without_removing_old_backup
    test_backup_replaces_existing_backup_root_with_current_snapshot
    test_backup_with_custom_backup_root_does_not_replace_sibling_preference_backups
    test_restore_skips_when_all_backups_missing_without_touching_target
    test_restore_applies_snapshot_for_managed_paths_only
    test_restore_helper_only_runs_when_enabled
    printf 'app_config tests passed\n'
}

main "$@"
