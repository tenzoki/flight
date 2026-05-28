---
description: Close the current flight session. Writes a session summary to flight-workbench/history/<session>-session.md, then compacts CLAUDE.md via a three-pass edit (add new learnings, update stale memos, prune obsolete content). Any open tasks generated during the session that were not resolved are carried forward into CLAUDE.md's Open tasks list. Run this when you are done for the day or session — it leaves the project in a clean state for next time.
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# /flight:land — close the session

Use this when you are done working. Land does three things:

1. **Finalizes the session history** — adds a summary block to today's `flight-workbench/history/<TS>-session.md`.
2. **Compacts CLAUDE.md** — three-pass edit: add (session learnings), update (refresh stale memos), prune (remove obsolete content). You will see what will change and can adjust.
3. **Carries forward unresolved tasks** — any open task that came up in the session but was not finished gets added to CLAUDE.md's Open tasks list before compaction.

After landing, the project is ready for the next session.

## Step 0 — Confirm

Brief the user on what will happen:

> **About to land this session.** I will:
> 1. Summarize this session into today's history file.
> 2. Add any unresolved tasks from this session to your open-task list.
> 3. Compact CLAUDE.md — adding new learnings, updating stale memos, pruning obsolete entries. I will show you the diff before applying.
>
> OK to proceed? (yes / skip compaction / cancel)

- **yes** — full landing (all three steps).
- **skip compaction** — finalize history and carry tasks forward, but leave CLAUDE.md content unchanged.
- **cancel** — exit without doing anything.

## Step 1 — Find the active session history file

Locate the most recent file in `flight-workbench/history/` matching `*-session.md`. That is the active session.

If multiple session files share today's date, pick the newest (latest mtime). If none exists, warn the user and offer to create one before continuing.

## Step 2 — Identify unresolved tasks from this session

Read the session history file. Scan the `## Log` section for any task-like entries that surfaced during the session — phrases like "TODO", "follow up", "we need to", "later", or tasks added via `/flight:memo` during this session.

Also: re-read CLAUDE.md and compare against the version recorded at session start (if available — `/flight:start` could record this; if not, just use the current state). Any task added during the session is already in CLAUDE.md. Any task **discussed but not yet recorded** should be picked up here.

For each candidate unresolved task, ask the user (group several into one `AskUserQuestion` if there are many):

> **Carry forward this task?** "<task description>"
>
> - **Yes, add to open tasks** (Recommended)
> - **No, drop it** — it was a passing thought
> - **Already done** — do not carry forward

For each "Yes", append the task to CLAUDE.md's `## Open tasks` section using the `/flight:memo` Step 2a procedure (date-prefixed line item).

## Step 3 — Write the session summary to history

Append a `## Summary` section to the active session history file:

```markdown
---

## Summary

**Ended:** <YYYY-MM-DD HH:MM>
**Duration:** <approx start-to-end>

### What we worked on

<3-7 bullet points: the main topics, documents produced, decisions filed>

### Files produced

- <path1> — <one-line description>
- <path2> — <one-line description>

### Decisions filed this session

- <path to decision> — <decision title>

(omit section if none)

### Open tasks carried forward

- <task line 1>
- <task line 2>

(omit section if none)
```

Then update the `**Status:**` line at the top of the file from `active` to `complete`.

## Step 4 — Append the session to CLAUDE.md's Recent sessions

In CLAUDE.md, locate the `## Recent sessions` section. Prepend a one-line entry:

```
- <YYMMDD-HH-MM> — <one-line session summary> (flight-workbench/history/<filename>)
```

If `## Recent sessions` has more than 5 entries after the prepend, move the oldest entries below the list under a `(older sessions in flight-workbench/history/)` line. Keep the top 5 visible.

## Step 5 — Compact CLAUDE.md (three-pass edit)

If the user chose "skip compaction" at Step 0, skip this entire step.

Otherwise, plan a three-pass edit:

### Pass 1 — Add

Identify content that should be added to CLAUDE.md based on this session:

- New project conventions established during the session.
- New context about the project, the user's preferences, or external constraints worth remembering.
- Updated language preference (if changed).

For each proposed addition, briefly note **what** and **where it goes** (which section).

### Pass 2 — Update

Identify content in CLAUDE.md that is now stale or imprecise:

- Project memos that were superseded by something said this session.
- Open-task descriptions that have evolved.
- Outdated references.

For each proposed update, note **the current text** and **the proposed new text**.

### Pass 3 — Prune

Identify content that is obsolete or no longer useful:

- Project memos that no longer apply.
- Resolved tasks that were not auto-detected by `/flight:cleanup`.
- Stale "Recent sessions" entries beyond the top 5.

For each proposed prune, note **the text to remove** and **why**.

### Present the plan

Before applying, show the user the full plan as a diff-like summary:

> **CLAUDE.md compaction plan:**
>
> **Additions (N):**
> - To `## Project memos`: "<new memo content>"
>
> **Updates (M):**
> - In `## Project memos`: replace "<old>" → "<new>"
>
> **Prunes (P):**
> - Remove from `## Project memos`: "<obsolete entry>" (reason: <why>)
>
> Apply all, review each, or cancel compaction?
>
> - **Apply all** (Recommended if the plan looks right)
> - **Review each** — confirm one by one via prompts
> - **Cancel compaction** — leave CLAUDE.md as-is

### Apply

If **Apply all**: use `Edit` calls to make every change. Add new content under the named section, update text with exact replacements, prune by removing exact lines.

If **Review each**: for each addition/update/prune, ask the user via `AskUserQuestion` whether to apply that specific change.

If **Cancel**: leave CLAUDE.md unchanged.

### Safety

Never remove the `## Open tasks` section or the `## How to behave in this project (for Claude)` section. Never remove a task from `## Open tasks` (that is `/flight:cleanup`'s job).

If the proposed plan would leave CLAUDE.md shorter than 30 lines, ask the user to confirm — that level of compaction usually means something important is being lost.

## Step 6 — Final report

> **Session landed.** History finalized, X unresolved tasks carried forward, CLAUDE.md compacted (A added / U updated / P pruned).
>
> **Details:**
> - Session history: `flight-workbench/history/<filename>`
> - Open tasks now: N
> - Project memos now: M
>
> Have a good one. Next time you start, `/flight:start` will pick up where we left off.

If the user chose "skip compaction", adjust the message:

> **Session landed (without CLAUDE.md compaction).** History finalized, X unresolved tasks carried forward. CLAUDE.md was left as-is.

## What this skill does NOT do

- Does not commit anything to git (flight does not assume git use).
- Does not delete the workbench or any history files.
- Does not run `/flight:cleanup` automatically — task hygiene is a separate explicit action.
