---
name: sync-dotfiles
description: Sync Claude config (skills, docs, CLAUDE.md) from dotfiles to ~/.claude/ using symlinks and interactive merge.
disable-model-invocation: true
---

Sync Claude configuration from this dotfiles repo to the user's `~/.claude/` directory.

**Source:** The `llms/claude/` directory in this repo (resolve its absolute path from the repo root).
**Target:** `~/.claude/`

## Steps

### 1. Sync skills (symlinks)

For each subdirectory in `<source>/skills/`:
- If `~/.claude/skills/<name>` is already a correct symlink → skip, report "already linked"
- If `~/.claude/skills/<name>` is a symlink pointing elsewhere → remove and re-create, report "updated"
- If `~/.claude/skills/<name>` exists but is NOT a symlink → warn the user and skip (don't overwrite real directories)
- If `~/.claude/skills/<name>` doesn't exist → create symlink, report "linked"

Create `~/.claude/skills/` if it doesn't exist.

### 2. Sync docs (symlinks)

For each file in `<source>/docs/`:
- Same logic as skills above, but for individual files
- Create `~/.claude/docs/` if it doesn't exist

### 3. Sync CLAUDE.md (interactive merge)

Compare `<source>/CLAUDE.md` with `~/.claude/CLAUDE.md`:
- If target doesn't exist → copy the source file, report "created"
- If target exists and is identical → skip, report "already up to date"
- If target exists and differs → show the diff to the user and ask:
  - **a)** Replace with dotfiles version
  - **b)** Keep existing version
  - **c)** Open side-by-side and let me merge manually (show both contents, then ask user for the final version)

### 4. Report summary

After all steps, print a summary table showing what was linked, updated, skipped, or warned about.
