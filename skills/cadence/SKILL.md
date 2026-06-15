---
description: Analyse this project's session logs, activity log, and git history to surface the work cadence — two ranked topic lists written to flight-workbench/cadence-<user>.md. List 1 is the topics of the last 7 days; list 2 is the recurring themes across the whole project history, ranked by churn (how many distinct sessions each theme keeps reappearing in). Reads session histories in flight-workbench/, fusion-workbench/, and scout-workbench/ (whichever exist), the shared activity-log-<user>.md (checked in both the project root and fusion-workbench/), and git commits. Use when the user asks "what have I been working on", "what are the recurring themes", "show my cadence", or wants a dated digest of recent and persistent topics.
allowed-tools: [Bash, Read, Glob, Grep, Write]
argument-hint: ""
---

# /flight:cadence — analyse logs and report the work cadence

When the user invokes `/flight:cadence`, read the project's log sources, identify the topics worked on, and write a digest with **two ranked lists** to `flight-workbench/cadence-$USER.md`:

1. **Topics of the last 7 days** — what the recent work has been about.
2. **Recurring themes by churn** — the themes that keep reappearing across the whole history, ranked by how many distinct sessions they show up in.

This is an **analysis** skill: you read the logs and identify topics by understanding them, not by keyword-matching. A topic is a short, human-readable theme label you assign (for example "scout plugin architecture", "browser-use no-cloud setup", "guard blocker on skills/"). Two log entries about the same thing in different words are the **same** topic — collapse them.

## Process

### 0. Anchor, detect workbenches, get the date and user

Cadence skills operate relative to the current directory. Establish where you are and what exists:

```bash
pwd
echo "$USER"
date +"%Y-%m-%d %H:%M"
ls -d ./flight-workbench ./fusion-workbench ./scout-workbench 2>/dev/null
```

- `$USER` fixes the output filename `cadence-$USER.md` and the activity-log filename `activity-log-$USER.md`.
- Today's date (from `date`, never from your own sense of "now" — your internal clock runs in UTC and will be off by the local offset) anchors the 7-day window.
- The three workbenches can coexist. Scan whichever are present; absent ones are not an error.

If none of the three workbenches and no `.git` are present here, tell the user there is nothing to analyse and suggest they re-run from the project root.

### 1. Compute the 7-day window

```bash
date +%Y-%m-%d                                  # today (window end)
date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d   # window start (BSD || GNU)
```

The recent window is `[window start, today]` inclusive. Use the two values literally; do not compute dates in your head.

### 2. Gather the log sources

Collect every available source. For each source record, per entry: a **date**, the **text** to read for topics, and a **source code** (legend below).

**Source legend:**

| Code | Source | Where |
|------|--------|-------|
| `hf` | flight session histories | `flight-workbench/history/*.md` |
| `hu` | fusion session histories | `fusion-workbench/history/*.md` |
| `hs` | scout session histories | `scout-workbench/history/*.md` |
| `a` | shared activity log | `activity-log-$USER.md` — check **both** `./` and `./fusion-workbench/` |
| `g` | git commits | `git log` (only if `.git` is present) |

```bash
# session histories (whichever workbenches exist) — `find` tolerates missing dirs
# and is glob-safe under zsh (a plain `ls a/*.md b/*.md` aborts when one glob misses)
find flight-workbench/history fusion-workbench/history scout-workbench/history -maxdepth 1 -name '*.md' 2>/dev/null

# activity log — TWO possible locations (root, and fusion-workbench where it may be moved to)
for f in "activity-log-$USER.md" "fusion-workbench/activity-log-$USER.md"; do [ -f "$f" ] && echo "$f"; done

# git commits with ISO dates (skip if not a git repo)
git log --date=short --pretty='%ad %h %s' 2>/dev/null
```

Note in the final report which sources were found and which were absent.

### 3. Date each log unit

Each **log unit** is one dated thing: one history file, one `## YYYY-MM-DD` day-section in the activity log, or one git commit. Derive its date in this order:

1. **Filename date token** on history files. Two conventions appear, parse both:
   - flight: `2026-06-14_10-58-session.md` → `2026-06-14`
   - fusion/scout: `260614-1058-orchestrator-session.md` → `20YY-MM-DD` from the leading `YYMMDD`
2. **`## YYYY-MM-DD` headers** inside the activity log — one unit per day-section.
3. **Commit date** for git units (the `%ad` field above).
4. **Fallback:** if a history file has no parseable date token, read its mtime: `date -r <file> +%Y-%m-%d`.

### 4. Extract topics per log unit

Read each log unit and identify the one or few topics it is about. Assign each a short theme label. Be consistent: reuse the **same** label every time the same theme recurs, so the churn count in step 6 is meaningful. Keep labels concrete — name the thing, not a vague bucket ("activity-log relocation", not "housekeeping").

For large histories, read enough of each file to identify its themes; you do not need every line, but do not judge a file by its title alone.

### 5. Build list 1 — topics of the last 7 days

Filter to log units whose date falls in `[window start, today]`. Collect the distinct topics in that window. For each, note where it appeared (source codes + dates). Order by how active the topic was in the window (most log units first). If the window is empty, say so plainly.

### 6. Build list 2 — recurring themes by churn

Across **all** log units (full history, not just the window), count each theme's **churn = the number of distinct sessions it appears in**. A "session" is one log unit as defined in step 3 (one history file, one activity-log day-section, or one git-commit day). Count each session once per theme even if the theme is mentioned several times inside it.

- Rank themes by churn, descending.
- Include only themes with churn **≥ 2** (a theme seen in a single session is not recurring — leave those for list 1, not here).
- For each theme record its **span**: earliest → latest date it appears. Span separates a long-running thread from a short burst of equal count.

### 7. Write `flight-workbench/cadence-$USER.md`

```bash
mkdir -p ./flight-workbench
```

Overwrite the file each run — it is a fresh snapshot, not an append log. Structure:

```markdown
# Cadence — <$USER>

**Generated:** <YYYY-MM-DD HH:MM, from `date`>
**Recent window:** <window start> → <today> (7 days)
**Sources scanned:** <e.g. fusion-workbench/history (14), git (37 commits); flight-workbench: absent, scout-workbench: absent, activity-log: none>

## Topics — last 7 days

- **<topic>** — <where it showed up: source codes + dates, one line>
- **<topic>** — ...

<!-- if the window is empty: -->
_No activity logged in the last 7 days (most recent log unit: <date>)._

## Recurring themes — by churn (distinct sessions)

| Rank | Theme | Sessions | Span (first → last) | Sources |
|------|-------|----------|---------------------|---------|
| 1 | <theme> | <n> | <first> → <last> | <codes> |
| 2 | ... | | | |

<!-- if nothing recurs ≥2: -->
_No theme recurs across two or more sessions yet._

## Notes

- <caveats: absent workbenches, undated files fallen back to mtime, activity-log location found, anything ambiguous>
```

### 8. Report to the user

In chat, give the headline: the top 2–3 recent topics and the top 2–3 recurring themes, plus the path to the written file. Keep it short; the file holds the detail. Apply the chat-voice profile.

## Graceful degradation

- **Only one workbench present** (the common case): scan it, note the others as absent. No warning needed.
- **No activity log:** note "activity-log: none" in the sources line; the histories and git carry the analysis.
- **Not a git repo:** skip the `g` source silently; note it in the sources line.
- **Nothing datable in the window:** still write the file, with the empty-window note in list 1.
- **Ambiguous or missing dates:** fall back to mtime (step 3.4) and record the fallback in Notes rather than guessing.

## What this skill is NOT

- It does not modify the source logs or the activity log — read-only on all inputs, writes only `flight-workbench/cadence-$USER.md`.
- It is not `/flight:log-activity`. That skill maintains the dated raw activity record; cadence is a higher-level digest built on top of it (and on the session histories and git). Run `/flight:log-activity` first if you want the activity log fresh before a cadence pass.
