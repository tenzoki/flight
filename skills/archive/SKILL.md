---
description: Archive completed or aged workbench files into flight-workbench/archive/<YYMMDD-HH-MM>-<slug>/. Supports natural-language description ("archive everything older than April", "archive the closed decisions") or pre-defined tiers (recent / mid / deep). Surveys, proposes, asks for confirmation, then moves. Use when the workbench has grown crowded and you want to thin it out without deleting anything.
argument-hint: [tier or natural-language description]
allowed-tools: [Read, Write, Bash, Edit, AskUserQuestion]
---

# /flight:archive — thin out the workbench

Move completed or aged files in the workbench into a single timestamped archive bundle. Nothing is deleted — everything stays on disk under `flight-workbench/archive/<YYMMDD-HH-MM>-<slug>/` and can be retrieved any time.

This is **distinct from `/flight:cleanup`**:
- `/flight:cleanup` operates on CLAUDE.md's open-task list only.
- `/flight:archive` operates on workbench files (history, decisions, memos).

## Step 1 — Determine scope

If the user passed text as an argument (e.g. `/flight:archive everything older than April`), use it. Otherwise, present three pre-defined tiers via `AskUserQuestion`:

- **Recent only (Recommended)** — archive history and memo files older than 14 days that have not been touched since. Keeps the workbench responsive without losing anything from the past two weeks.
- **Mid** — archive everything older than 60 days. Suitable for periodic cleanup.
- **Deep** — archive everything older than 180 days. For workbenches that have accumulated years of context.
- **Other** — let the user describe in their own words (date range, file types, topic).

For natural-language scope, parse the user's text to determine: date range (older than X / between A and B), file types (history / memos / decisions / all), and any topic filter.

## Step 2 — Survey

Walk `flight-workbench/history/`, `flight-workbench/memos/`, and `flight-workbench/decisions/`. For each file, check the mtime and filename date prefix. Build a candidate list of files that match the scope.

**Never include** in candidates:
- `flight-workbench/.flight-setup`
- `flight-workbench/stilwerk/*` — these are reference files, not user content
- Any file modified in the last 24 hours
- Today's active session history file
- The `flight-workbench/archive/` folder itself

## Step 3 — Propose

Show the user the candidate list grouped by folder, with counts:

> **Archive proposal**
>
> Will move N files into `flight-workbench/archive/<YYMMDD-HH-MM>-<slug>/`:
>
> **From `history/` (X files):**
> - <YYMMDD-HH-MM>-session.md (modified <date>)
> - ...
>
> **From `memos/` (Y files):**
> - <filename> (modified <date>)
> - ...
>
> **From `decisions/` (Z files):**
> - <filename> (modified <date>)
> - ...
>
> Proceed? (yes / review each / cancel)

- **yes** — move everything in the candidate list.
- **review each** — walk through each file via `AskUserQuestion` (Archive / Keep).
- **cancel** — exit without changes.

If the candidate list is empty:

> **Nothing to archive.** No files match the scope. Try a wider scope (e.g. `/flight:archive everything older than April`).

## Step 4 — Generate the archive slug

Build a short kebab-case slug describing the scope (`older-than-14d`, `mid-tier`, `closed-decisions`, `pre-april-2026`, etc.). Get the timestamp: `date +%y%m%d-%H-%M`.

Create the archive bundle directory:

```bash
TS="$(date +%y%m%d-%H-%M)"
SLUG="<slug>"
mkdir -p "./flight-workbench/archive/${TS}-${SLUG}/history" "./flight-workbench/archive/${TS}-${SLUG}/memos" "./flight-workbench/archive/${TS}-${SLUG}/decisions"
```

## Step 5 — Move the files

For each file in the confirmed list, move it into the matching subfolder of the archive bundle, preserving the filename:

```bash
mv "./flight-workbench/history/<file>" "./flight-workbench/archive/${TS}-${SLUG}/history/"
```

Use `mv` (not `cp`) — the file leaves its original folder. The archive is the canonical location after this point.

## Step 6 — Write an index

Write `./flight-workbench/archive/<TS>-<SLUG>/README.md`:

```markdown
# Archive — <YYMMDD-HH-MM> — <human-readable scope>

**Created:** <YYYY-MM-DD HH:MM>
**Scope:** <user's scope description or tier label>
**Total files:** N

## history/ (X files)

- <filename> — <one-line summary if derivable from first line>

## memos/ (Y files)

- <filename> — <one-line summary>

## decisions/ (Z files)

- <filename> — <decision title>

## How to retrieve

These are normal files. To use one again, copy or move it back from `flight-workbench/archive/<this-folder>/<subfolder>/<filename>` to its original location in `flight-workbench/`.
```

## Step 7 — Append to session history

Add one line to today's session history file:

```
- <HH:MM> archive: moved N files to flight-workbench/archive/<TS>-<SLUG>/
```

## Step 8 — Report

> **Archive complete.** Moved N files into `flight-workbench/archive/<TS>-<SLUG>/`.
>
> Open `flight-workbench/archive/<TS>-<SLUG>/README.md` for the index. Files can be moved back any time.

## What this skill does NOT do

- Does not delete any file. Everything is moved, not removed.
- Does not modify CLAUDE.md.
- Does not archive style profiles (`stilwerk/`) or the setup marker.
