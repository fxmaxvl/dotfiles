---
name: bfeature-design
description: Produce a shareable system-design document (with diagrams) from a high-level idea via interactive Q&A. Standalone — no git, no branches, no PR. Optionally seeds /bfeature.
disable-model-invocation: false
argument-hint: [idea description]
allowed-tools: Read, Write, Glob, Grep, mcp__claude_ai_Excalidraw__create_view, mcp__claude_ai_Excalidraw__export_to_excalidraw, mcp__claude_ai_Excalidraw__read_checkpoint, mcp__claude_ai_Excalidraw__read_me, mcp__claude_ai_Excalidraw__save_checkpoint
---

Orchestrate a 4-phase design flow: Gather → Generate → Review → Optional /bfeature handoff. This skill is standalone — no git work, no build-state.json, no branches, no PR. Re-invoking the skill does NOT resume a previous session — there is no state file.

## Sub-skill Resolution

Sub-skills are **not registered** with the Skill tool and cannot be invoked via `Skill(name)`. Locate them using `Glob("~/.claude/skills/bfeature-design/**/SKILL.md")`.

**Reading the sub-skill's SKILL.md is mandatory before executing that phase.** Never skip this step.

Two invocation patterns are used in this skill:

- **Inline** (gather, review, handoff): Read the SKILL.md and follow its instructions directly in the current conversation. Do **not** use the Agent tool.
- **Agent** (generate): Read the SKILL.md and pass its full contents as the agent's `prompt`. Always pass `model: opus`.

## Status Banners

At the start of every phase, print a banner so the user knows where they are. Print as plain text (not in a code block):

```
── bfeature-design | Name ───────────────────────────────
```

The Generate banner is **required** and must include the timing note:

```
── bfeature-design | Generate (may take 1–2 min) ──────────
```

## Phase Flow

```
gather (inline Q&A) → generate (opus agent) → review (inline) → handoff? (inline)
```

## On Invocation

1. If `$ARGUMENTS` is empty or whitespace-only: ask the user one question — "What do you want to design?" — and use their answer as the idea.
2. Otherwise, use `$ARGUMENTS` verbatim as the idea. Do not truncate or preprocess it, even if it is a multi-paragraph paste.
3. Compute a session timestamp in `YYYYMMDDTHH` format (e.g., `20260420T14`). Store it for the temp Q&A file path. The temp file path will be `/tmp/bfeature-design-qa-<timestamp>.md`.

## Phase 1 — Gather

── bfeature-design | Gather ───────────────────────────────

1. Read `~/.claude/skills/bfeature-design/gather/SKILL.md` and follow its instructions **inline** in the current conversation. Pass the idea as `$ARGUMENTS`.

2. When gather returns:

   **On cancellation** (gather returns `BFEATURE_DESIGN_CANCELLED`):
   - Delete the temp Q&A file at `/tmp/bfeature-design-qa-<timestamp>.md` if it exists.
   - Print: "Cancelled — no design doc produced."
   - Exit. Do NOT write a design doc.

   **On success** (gather returns `BFEATURE_DESIGN_QA_COMPLETE` with the structured Q&A):
   - Serialize the Q&A to `/tmp/bfeature-design-qa-<timestamp>.md` using this format:

     ```markdown
     # Bfeature-Design Q&A

     ## Original Idea
     <original idea text>

     ## Clarifications
     **Q: <question>**
     A: <answer>

     **Q: <question>**
     A: <answer>
     ```

   - If the Write fails for any reason (disk full, permission denied, sandboxing, etc.), abort immediately with a clear error:

     ```
     Cannot write Q&A transcript to /tmp/bfeature-design-qa-<timestamp>.md — <reason>. Cannot continue.
     ```

     Do NOT silently continue without the transcript.

3. Proceed to Phase 2.

## Phase 2 — Generate

── bfeature-design | Generate (may take 1–2 min) ──────────

1. **Derive a slug** from the original idea:
   - Convert to kebab-case and ASCII characters only (strip accents and non-ASCII).
   - Remove common filler words: a, an, the, of, to, in, for, on, at, by, with, and, or, but.
   - Cap at 40 characters, truncating at the nearest **word boundary before** the 40-char limit (never cut mid-word).
   - If the result is empty, too short (≤ 3 chars), or consists only of filler, append a `-<YYYYMMDD>` timestamp suffix for uniqueness (e.g., `design-20260420`).

2. **Compute the output path:**
   ```
   <cwd>/<slug>-design.md
   ```
   Use the current working directory where the skill was invoked — NOT `git rev-parse --show-toplevel`. Never derive the path from the git root.

3. **Handle filename collisions:** If `<slug>-design.md` already exists in cwd, try `<slug>-design-2.md`, `<slug>-design-3.md`, and so on until a free name is found. Never silently overwrite an existing file. Inform the user: "Found an existing file; saved as `<new-name>`."

4. **(Optional) Confirm the slug:** Before invoking the agent, show the user the derived slug and ask if they want to override it. One short question — not a full Q&A. If the user overrides, re-apply the collision check.

5. **Invoke the generate agent:**
   - Read `~/.claude/skills/bfeature-design/generate/SKILL.md`.
   - Pass its full contents as an Agent prompt with `model: opus`.
   - The agent prompt must include:
     - The absolute path to the temp Q&A file from Phase 1 (`/tmp/bfeature-design-qa-<timestamp>.md`).
     - The absolute path to the target design doc file computed above.
     - No inline Q&A text — the agent reads the Q&A file itself.

6. **Retry once on failure:** If the agent returns an error, produces malformed output, or the output file is not written (or is written but is < 200 bytes as a sanity check), retry the agent call once automatically. On a second failure, abort the session:
   ```
   Generate failed after one retry: <error summary>. No design doc was written.
   ```
   Do NOT attempt a third retry.

7. **On success:** Tell the user:
   - The **absolute path** of the generated doc.
   - A brief summary: sections present, diagram count, diagram tool used (Excalidraw or Mermaid).
   
   Then proceed to Phase 3.

## Phase 3 — Review

TODO: added in step 6.

## Phase 4 — Optional /bfeature handoff

TODO: added in step 7.

Here is the idea:
$ARGUMENTS
