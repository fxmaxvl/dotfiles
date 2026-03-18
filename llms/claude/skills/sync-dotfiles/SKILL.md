---
name: sync-dotfiles
description: Sync Claude config (skills, docs, CLAUDE.md) from dotfiles to ~/.claude/ using symlinks and interactive merge.
disable-model-invocation: true
---

Sync Claude configuration from this dotfiles repo to the user's `~/.claude/` directory.

## How to run

Run the helper script from the skill directory:

```bash
bash skills/sync-dotfiles/sync.sh
```

The script handles everything automatically:
- **Skills**: symlinks each skill subdirectory (except `sync-dotfiles` itself) into `~/.claude/skills/`
- **Docs**: symlinks each doc file into `~/.claude/docs/`
- **Stale cleanup**: removes symlinks that point back to source but no longer have a matching entry
- **CLAUDE.md**: copies if missing, skips if identical

## Interactive resolution (exit code 2)

If `CLAUDE.md` differs between source and target, the script exits with code **2** and prints a unified diff. When this happens, ask the user:

- **a)** Replace with dotfiles version — run: `cp <SOURCE> <TARGET>` (paths printed by the script)
- **b)** Keep existing version — no action needed
- **c)** Manual merge — show both file contents side-by-side and let the user decide

## Dry run

```bash
bash skills/sync-dotfiles/sync.sh --dry-run
```

Shows what would happen without making changes.
