#!/usr/bin/env bash
# sync-dotfiles helper — syncs skills, docs, and CLAUDE.md from dotfiles repo to ~/.claude/
# Usage: sync.sh [--dry-run]
#
# Exit codes: 0 = success, 1 = error
# When CLAUDE.md differs, exits with code 2 and prints the diff for interactive resolution.

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Resolve source directory (the llms/claude/ dir in the dotfiles repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET="$HOME/.claude"

# Summary tracking
declare -a SUMMARY=()

log() { SUMMARY+=("$1"); echo "$1"; }

sync_symlinks() {
    local src_dir="$1" tgt_dir="$2" item_type="$3" skip_pattern="${4:-}"

    # Create target dir if needed
    if [[ ! -d "$tgt_dir" ]]; then
        if $DRY_RUN; then
            log "[dry-run] would create $tgt_dir/"
        else
            mkdir -p "$tgt_dir"
            log "created $tgt_dir/"
        fi
    fi

    # Sync items from source
    if [[ -d "$src_dir" ]]; then
        for src_item in "$src_dir"/*; do
            [[ ! -e "$src_item" ]] && continue
            local name
            name="$(basename "$src_item")"

            # Skip pattern (e.g., sync-dotfiles itself)
            [[ -n "$skip_pattern" && "$name" == "$skip_pattern" ]] && continue

            # For skills: only sync directories. For docs: only sync files.
            if [[ "$item_type" == "dir" && ! -d "$src_item" ]]; then continue; fi
            if [[ "$item_type" == "file" && ! -f "$src_item" ]]; then continue; fi

            local tgt_item="$tgt_dir/$name"

            if [[ -L "$tgt_item" ]]; then
                local current_target
                current_target="$(readlink "$tgt_item")"
                if [[ "$current_target" == "$src_item" ]]; then
                    log "  $name — already linked ✓"
                else
                    if $DRY_RUN; then
                        log "  $name — [dry-run] would update symlink"
                    else
                        rm "$tgt_item"
                        ln -s "$src_item" "$tgt_item"
                        log "  $name — updated ↻"
                    fi
                fi
            elif [[ -e "$tgt_item" ]]; then
                log "  $name — WARNING: exists but is not a symlink, skipping ⚠"
            else
                if $DRY_RUN; then
                    log "  $name — [dry-run] would link"
                else
                    ln -s "$src_item" "$tgt_item"
                    log "  $name — linked ✓"
                fi
            fi
        done
    fi

    # Clean up stale symlinks (only those pointing into our source dir)
    if [[ -d "$tgt_dir" ]]; then
        for tgt_item in "$tgt_dir"/*; do
            [[ ! -L "$tgt_item" ]] && continue
            local link_target
            link_target="$(readlink "$tgt_item")"
            # Only manage symlinks that point into our source
            if [[ "$link_target" == "$src_dir/"* ]]; then
                local name
                name="$(basename "$tgt_item")"
                if [[ ! -e "$src_dir/$name" ]]; then
                    if $DRY_RUN; then
                        log "  $name — [dry-run] would remove (stale)"
                    else
                        rm "$tgt_item"
                        log "  $name — removed (stale) 🗑"
                    fi
                fi
            fi
        done
    fi
}

sync_claude_md() {
    local src="$SOURCE/CLAUDE.md" tgt="$TARGET/CLAUDE.md"

    if [[ ! -f "$tgt" ]]; then
        if $DRY_RUN; then
            log "CLAUDE.md — [dry-run] would create"
        else
            cp "$src" "$tgt"
            log "CLAUDE.md — created ✓"
        fi
        return 0
    fi

    if diff -q "$src" "$tgt" >/dev/null 2>&1; then
        log "CLAUDE.md — already up to date ✓"
        return 0
    fi

    # Files differ — print diff and exit with code 2 for interactive resolution
    echo "CLAUDE.md — files differ, interactive resolution needed:"
    echo "---"
    diff -u "$tgt" "$src" --label "~/.claude/CLAUDE.md (current)" --label "dotfiles CLAUDE.md (incoming)" || true
    echo "---"
    echo "CLAUDE_MD_SOURCE=$src"
    echo "CLAUDE_MD_TARGET=$tgt"
    return 2
}

# --- Main ---
echo "=== Syncing skills ==="
sync_symlinks "$SOURCE/skills" "$TARGET/skills" "dir" "sync-dotfiles"

echo ""
echo "=== Syncing conventions ==="
sync_symlinks "$SOURCE/conventions" "$TARGET/conventions" "file"

echo ""
echo "=== Syncing CLAUDE.md ==="
claude_md_rc=0
sync_claude_md || claude_md_rc=$?

echo ""
echo "=== Summary ==="
for line in "${SUMMARY[@]}"; do
    echo "$line"
done

exit "$claude_md_rc"
