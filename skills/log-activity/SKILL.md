---
description: Scan this project's activity and generate or update the user's activity log at activity-log-<user>.md in the project root. Pulls from git commits (when the project is a git repo) and the flight-workbench (history, decisions, memos). If fusion (flight's big brother) already manages an activity-log file in this project, flight reuses that same file and merges its own entries in — no duplicate file, no clobbered fusion entries. Use when the user asks "log my activity", "update the activity log", or wants a dated record of what happened in the project.
allowed-tools: [Bash, Read, Glob, Grep, Write, Edit]
---

# /flight:log-activity — scan project activity and write the activity log

When the user invokes `/flight:log-activity`, scan the project's activity sources and create or update the user's activity log file in the project root.

The activity log is a **shared deliverable**. Its filename — `activity-log-$USER.md` — is the same one fusion uses. If fusion already created it, flight does **not** make a second file: it reuses the existing one and merges flight's entries into it, skipping any date fusion already logged. If no log exists, flight creates it. Either way there is exactly one `activity-log-$USER.md` per user per project.

## Process

### 0. Anchor to the project root

Flight skills operate relative to the current directory. Confirm where you are and detect the workbench(es):

```bash
pwd
ls -d ./flight-workbench ./fusion-workbench 2>/dev/null
```

The activity log lands at `./activity-log-$USER.md` (project root, next to `CLAUDE.md`). Flight and fusion can coexist in one project:

- `./flight-workbench/` present → flight's own scaffolding; scan it (Step 3).
- `./fusion-workbench/` present → fusion is also active here. Its own `/fusion:log-activity` covers the fusion sources; flight does not re-scan them. Flight only **reuses the shared log file** fusion writes (Step 2) and adds entries from flight's sources.
- Neither present → there is no workbench to scan. Flight can still log git activity (Step 3a). Warn the user that without a `flight-workbench/` there are no history/decision/memo sources, and suggest `/flight:start` if they want one.

If the user is not at the project root (no workbench and no `.git` here), tell them the log will land in the current directory and let them re-run from the right place if that is wrong.

### 1. Determine the current user

```bash
echo "$USER"
```

The activity log file is `activity-log-$USER.md` in the project root. For example, if `$USER` is `kai`, the file is `activity-log-kai.md`. This matches fusion exactly, so the file is interchangeable between the two tools.

### 2. Check for an existing log file (flight- or fusion-managed)

- If `activity-log-$USER.md` exists, read it. It may have been created by fusion, by a previous flight run, or by both — the format is shared, so treat it uniformly.
  - Extract the dates already logged: look for `## YYYY-MM-DD` headers.
  - Only process dates **not** yet logged. Never duplicate a day fusion (or a prior flight run) already wrote.
  - Preserve the existing header, `## Source Legend`, `## High-level arc`, `## Active Hours per Week`, and `## Total commits` sections. If flight introduces a source code the legend does not yet list (see Step 3), add only the missing row — do not rewrite the legend.
- If the file does not exist, create it from scratch (Step 5 header).

### 3. Scan flight's activity sources

Collect timestamped activity. For each item record: timestamp, topic/description, source code.

**Source legend (flight):**

| Code | Source | Path |
|------|--------|------|
| `g` | git commits | `git log` |
| `h` | history files | `flight-workbench/history/` |
| `d` | decisions | `flight-workbench/decisions/` |
| `m` | memos & tasks | `flight-workbench/memos/` |
| `k` | deliverables | project-root `*.md` produced by flight (excluding `CLAUDE.md`, `README.md`, and the activity log itself) |

These codes are deliberately compatible with fusion's: `g`/`h`/`d` mean the same thing in both tools, so a shared file stays coherent. `m` (memos) and `k` (deliverables) are flight-specific; add their legend rows only if flight actually emits entries with those codes.

**Scanning methods:**

a) **Git commits** (`g`) — only if this is a git repository. Mirror fusion's approach:

   ```bash
   git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git log --format="%ai|%s" --since="30 days ago"
   ```

   If `git rev-parse` fails (not a git repo, or git not installed), **skip the git source entirely** and proceed with workbench sources only — do not error. Otherwise parse each line for date, time, and commit subject.

b) **Workbench files** (`h`, `d`, `m`) — only scan directories that exist:
   - `ls -la` each directory to get modification times.
   - Parse filenames for embedded timestamps. Flight's default file prefix is `YYYY-MM-DD_HH-MM` (e.g. `2026-06-08_07-15-session.md` → June 8, 07:15); the prefix is configurable via `FLIGHT_FILE_PREFIX`, so also accept the fusion-style `YYMMDD-HHMM` pattern (e.g. `260608-0715-...` → June 8, 07:15) for files written under other conventions.
   - For `flight-workbench/history/*-session.md`, read the `## Summary` one-liner (or `## Log` entries) for the day's theme.
   - For `flight-workbench/memos/`, use dated `##` sections inside `memos-$USER.md` and date-prefixed lines in `tasks-$USER.md`.

c) **Deliverables** (`k`) — project-root `*.md` files flight produced, using file modification time. Exclude `CLAUDE.md`, `README.md`, `LICENSE`, and `activity-log-*.md`. Keep this light: one entry per deliverable touched on a given day.

### 4. Group by date

- Group all collected activities by calendar date; sort within each date by timestamp.
- For each date determine:
  - **Start hour:** earliest activity timestamp.
  - **End hour:** latest activity timestamp.
  - If end time is after midnight (00:00–05:00), treat it as an extension of the previous day: add 24 to the hour. Example: activity from 11:00 to 02:30 next day becomes `[11-26]`.
- **Inactive days within the span:** if a date between the earliest logged date and today has **no** activity from any source, still emit a daily header `## YYYY-MM-DD (Day) [—]` with no time table. This preserves continuity for the per-week aggregation in Step 6. The inactive marker is the em-dash U+2014 (`—`) — not a hyphen, en-dash, or double-hyphen.

### 5. Format output

#### New file header (only when creating a new file)

```markdown
# Activity Log — <User Name>

**Project:** <project name from CLAUDE.md or directory name>
**Started:** <earliest date found>

## Source Legend

| Code | Source |
|------|--------|
| g | git commits |
| h | history files |
| d | decisions |
| m | memos & tasks |
| k | deliverables |

## High-level arc

<!-- One bullet per logged day, NEWEST FIRST. Bullet format:
     - **MM-DD Day** [start-end] — one-line theme -->

## Active Hours per Week

<!-- Inserted by Step 6. Newest week first. -->

## Daily Log
```

When **reusing a fusion-managed file**, do not rewrite its header or legend. Keep fusion's legend as-is; if flight emits an `m` or `k` entry and that row is absent, append just that row.

The end-of-file `## Total commits` section is appended on initial create and refreshed on each run — see Step 7.

#### Per-day entry

For each new day (not already in the log):

```markdown
## YYYY-MM-DD (Day) [startHr-endHr]

| Time | Topic | Src |
|------|-------|-----|
| HH:MM | <description> | g |
| HH:MM | <description> | h |
| ... | ... | ... |
```

Also prepend a one-line bullet to `## High-level arc` (newest-first):

```markdown
- **MM-DD Day** [startHr-endHr] — one-line theme
```

Infer the theme from commit messages, session summaries, decision/memo topics (e.g. "drafted the auditor reply", "reviewed the v2 schema").

### 6. Build the per-week Active Hours table — MANDATORY, atomic with each new day

For each new day added to the Daily Log, locate the ISO week (Mon–Sun) it falls into and update the corresponding row in `## Active Hours per Week` (insert if absent; recompute `Days active` and `Avg active hours/day` if present).

**Format:**

```markdown
## Active Hours per Week

| Week of (Mon) | Days active | Avg active hours/day |
|---------------|-------------|----------------------|
| YYYY-MM-DD    | N           | H.H                  |
```

- **Week label:** `YYYY-MM-DD` of the Monday of the ISO week.
- **Days active:** count of days in the week with a parseable `[start-end]` range (not `[—]`). A degenerate `[H-H]` range counts as an active day even though elapsed hours are 0.
- **Avg active hours/day:** (sum hours) / (days active), one decimal. Print `n/a` if days_active == 0.

**Hour arithmetic:**
- Single range `[A-B]` → hours = (B − A); if B < A (cross-midnight), use (B + 24 − A).
- Degenerate `[H-H]` → 0 hours, but counts as an active day.

**Ordering:** newest week first. **Placement:** between `## High-level arc` and `## Daily Log`.

**Atomicity contract:** when you add a daily entry you MUST update its per-week row in the same write. Either both land or neither lands.

**Verification before declaring this step done** — every distinct ISO week represented by a daily entry has exactly one row in the per-week table. Run each command on a single line (no backslash-newline continuations):

```bash
daily_entries=$(grep -c "^## 2[0-9]\{3\}-" activity-log-$USER.md)
week_rows=$(grep -cE "^\| [0-9]{4}-[0-9]{2}-[0-9]{2} +\|" activity-log-$USER.md)
distinct_iso_weeks=$(grep -oE "^## [0-9]{4}-[0-9]{2}-[0-9]{2}" activity-log-$USER.md | sed 's/^## //' | xargs -I{} date -j -f "%Y-%m-%d" {} +"%Y-W%V" 2>/dev/null | sort -u | wc -l | tr -d ' ')
echo "$daily_entries daily entries, $week_rows week rows, $distinct_iso_weeks distinct ISO weeks"
[ "$distinct_iso_weeks" = "$week_rows" ] || echo "MISMATCH: $distinct_iso_weeks distinct ISO weeks vs $week_rows week rows"
```

The `date -j -f` form is macOS-native. On GNU/Linux substitute `date -d "{}" +"%Y-W%V"`. The `2>/dev/null` swallows per-line parse errors so a malformed date doesn't abort the pipeline.

If a distinct ISO week is missing from the table — or a row has no matching daily entry — fix before writing.

### 7. Write output

- On **create:** header + reversed-order `## High-level arc` (newest day first) + `## Active Hours per Week` + Daily Log entries (chronological — per-day sections are NOT reversed; only the arc bullets are newest-first) + `## Total commits`.
- On **append / reuse:** insert new daily entries chronologically into `## Daily Log`; prepend the new arc bullet at the top of `## High-level arc`; update or insert per-week rows (recomputing both columns when a row is touched); refresh `## Total commits`. Never duplicate entries, and never touch a day already present (fusion's or flight's).

**End-of-file commit-count section** (append on create, refresh every run; skip entirely if not a git repo):

```markdown
## Total commits

<N> git commits since project start (<earliest date>).
```

`<N>` comes from (git-repo only):

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && git log --since=<earliest-date> --oneline | wc -l
```

If the project is not a git repo, omit the `## Total commits` section (and remove a stale one only if it was flight-written; leave a fusion-written one untouched).

### 8. Report to the user

Tell the user:
- How many new days were logged, and the date range covered.
- Whether the log was **created** fresh or **reused** an existing (fusion- or flight-managed) file.
- Number of new per-week rows added (if any) and the three verification numbers from Step 6, printed explicitly: `<N> daily entries`, `<W> per-week rows`, `<W'> distinct ISO weeks` — do not collapse to "OK".
- Whether git was used or skipped (not a git repo).
- Path to the activity log file and the current total commit count (if git).

## Notes

- **Reuse, never duplicate.** The whole point of the shared filename is that flight and fusion write the *same* `activity-log-$USER.md`. Read existing `## YYYY-MM-DD` headers first; only add days that are missing. Never create `activity-log-$USER-flight.md` or similar.
- **Git is optional.** If the project is not a git repository, skip every git step silently and log workbench activity only. If it is a repo, use git exactly as fusion does.
- **Be thorough but light.** Scan all flight source directories that exist; one or two lines per day is fine. Even a single commit or memo is worth a daily entry.
- The High-level arc lists newest day first; the Daily Log itself is chronological (oldest → newest).
- Flight never writes activity tracking into `CLAUDE.md` — that file is shared with other tools. The activity log is a project-root deliverable, like flight's other outputs.
