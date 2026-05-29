---
description: Clean up CLAUDE.md's open-task list. Removes tasks the user has marked closed, and for tasks that look obviously outdated or redundant, asks the user whether to archive, delete, or keep each. Strippings go to flight-workbench/archive/<timestamp>-cleanup-strippings.md so nothing is lost. Run when the open-task list has grown long or stale; complements /flight:land (which is broader: session close + full CLAUDE.md compaction).
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# /flight:cleanup — strip closed and stale tasks from CLAUDE.md

The open-task list in `CLAUDE.md` accumulates over time. This skill:

1. **Removes** tasks the user has explicitly marked closed (any line beginning with `- [x]`, `- ✓`, `- [DONE]`, or containing `(closed)` / `(done)` / `(resolved)` at end).
2. **Reviews** tasks that look outdated or redundant, asking the user case-by-case: archive, delete, or keep.
3. **Archives** everything removed to a single timestamped file under `flight-workbench/archive/`, so nothing is permanently lost.

This is narrower than `/flight:land`. Cleanup only touches the task list. Land does much more (session summary, full CLAUDE.md compaction, history finalization).

## Step 1 — Read CLAUDE.md and locate the task list

Read `./CLAUDE.md`. Locate the `## Open tasks` section. Extract every list item. Note their line positions for later replacement.

If the section has no tasks (or only the placeholder), tell the user and exit:

> **Nothing to clean up.** Your open-task list is empty.

## Step 2 — Auto-classify

For each task line, classify as:

- **Closed** — line starts with `- [x]`, `- ✓`, `- [DONE]`, `- [done]`, or contains `(closed)`, `(done)`, `(resolved)`, or `RESOLVED` at end. These will be removed without asking.
- **Stale-looking** — line has a date prefix matching the project's `FLIGHT_FILE_PREFIX` shape (default `YYMMDD-HHMM`) and the date is more than 30 days old AND nothing in the line indicates it is recurring or pinned. Flag for user review.
- **Redundant** — two or more tasks reference the same subject (substring similarity heuristic). Flag the group for user review.
- **Current** — everything else. Keep.

## Step 3 — Confirm closed-task archive

Show the user the closed-task list (if any) before removing:

> **Found N closed tasks to archive:**
> - <task 1>
> - <task 2>
>
> Archive all and remove from CLAUDE.md? (yes / no / let me review)

On yes: proceed to archival. On no: skip. On review: walk through each via `AskUserQuestion` (Archive / Keep).

## Step 4 — Review stale and redundant tasks

For each flagged stale or redundant task (or group), use `AskUserQuestion`:

> **Task:** "<task text>" (filed <date>)
>
> What should I do with this?
>
> - **Archive** — move to archive file, remove from CLAUDE.md (Recommended for stale)
> - **Delete** — remove without archiving (only if truly meaningless)
> - **Keep** — leave it in the open-task list

For redundant groups, present the group together and ask which to keep (if any) and which to archive.

## Step 5 — Write the archive file

Get timestamp: `date +"${FLIGHT_FILE_PREFIX:-%y%m%d-%H%M}"` (env var overrides default; default renders as `YYMMDD-HHMM`). Create:

```
./flight-workbench/archive/<prefix>-cleanup-strippings.md
```

Content:

```markdown
# Cleanup strippings — <YYYY-MM-DD HH:MM>

Tasks removed from CLAUDE.md during `/flight:cleanup`.

## Closed tasks

- <task line 1, as it appeared>
- <task line 2>

## Archived as stale

- <task line>

## Archived as redundant (kept: "<the one preserved>")

- <task line>
```

Omit sections that have no entries.

If the user chose **Delete** for any tasks, list them in a final section so the choice is auditable:

```markdown
## Deleted (per user)

- <task line>
```

## Step 6 — Rewrite CLAUDE.md's Open tasks section

Use the `Edit` tool to replace the `## Open tasks` section's body with the surviving tasks (in the order they originally appeared, with closed/archived/deleted entries removed).

If the surviving list is empty, restore the placeholder:

```
(No open tasks yet. Use `/flight:memo <task>` to add one, or just tell Claude in chat — Claude will offer to file it here.)
```

## Step 7 — Append a log entry to the session history

Append one line to today's session history (find the latest `flight-workbench/history/<TS>-session.md`):

```
- <HH:MM> cleanup: removed N tasks (M closed, S stale, R redundant) → flight-workbench/archive/<archive-filename>
```

## Step 8 — Report

> **Cleanup done.** Removed N tasks from your open-task list (M closed, S archived as stale, R archived as redundant, D deleted). Your active task count is now K.
>
> **Archive:** `flight-workbench/archive/<filename>` — open it to see what was removed.
