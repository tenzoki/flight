---
description: Analyse this project's session logs, activity log, and git history to surface the work cadence — three ranked topic lists written to flight-workbench/cadence-<user>.md. List 1 is the topics touched since yesterday (and on Mondays, Friday+Saturday+Sunday collapsed together) up to now; list 2 is the topics of the last 7 days; list 3 is the recurring themes across the whole project history, ranked by churn (how many distinct sessions each theme keeps reappearing in). Reads session histories in flight-workbench/, fusion-workbench/, and scout-workbench/ (whichever exist), the shared activity-log-<user>.md (checked in both the project root and fusion-workbench/), and git commits. Use when the user asks "what have I been working on", "what did I do yesterday", "what are the recurring themes", "show my cadence", or wants a dated digest of recent and persistent topics.
allowed-tools: [Bash, Read, Glob, Grep, Write]
argument-hint: ""
---

# /flight:cadence — analyse logs and report the work cadence

When the user invokes `/flight:cadence`, read the project's log sources, identify the topics worked on, and write a digest with **three ranked lists** to `flight-workbench/cadence-$USER.md`:

1. **Topics since yesterday** — what was touched from yesterday up to now. On a Monday, "yesterday" is a Sunday, so this collapses Friday + Saturday + Sunday into one bucket (the weekend's last working stretch).
2. **Topics of the last 7 days** — what the recent work has been about.
3. **Recurring themes by churn** — the themes that keep reappearing across the whole history, ranked by how many distinct sessions they show up in.

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

### 1. Compute the time windows

Two windows anchor the recent lists. Compute both with `date` — never in your head.

```bash
today=$(date +%Y-%m-%d)                                    # window end (now / "until currently")
dow=$(date +%u)                                            # today's weekday: 1=Mon … 7=Sun

# 7-day window start
week_start=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)

# "yesterday" window start. Yesterday is a Sunday exactly when today is Monday (dow=1);
# in that one case reach back to Friday so Fri+Sat+Sun collapse into a single bucket.
if [ "$dow" -eq 1 ]; then back=3; else back=1; fi          # Mon → back to Fri, else → yesterday
yday_start=$(date -v-"${back}"d +%Y-%m-%d 2>/dev/null || date -d "${back} days ago" +%Y-%m-%d)

[ "$back" -eq 3 ] && weekend="yes (Fri–Sun)" || weekend="no"
echo "today=$today  week_start=$week_start  yday_start=$yday_start  weekend_collapsed=$weekend"
```

- **Recent (7-day) window:** `[week_start, today]` inclusive.
- **Yesterday window:** `[yday_start, today]` inclusive — "the day before, up to now". When today is Monday, `yday_start` is the preceding **Friday**, so Friday, Saturday and Sunday are reported together. Otherwise `yday_start` is plain yesterday.

Use the printed values literally.

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

**Exclude tooling/meta topics — they are not work.** The internal bookkeeping of flight, fusion, and scout is not a topic the user works *on*; they work *through* these tools. Drop such topics from **every** list — the yesterday list, the 7-day list, and the churn ranking. Do not let them surface even when they recur often (their churn is high precisely because the tools run every session — that is noise, not a theme). Drop, for example:

- session / orchestrator **setup**, "awaiting scope/directive", Phase-0 scaffolding
- **workbench tracking & housekeeping**, history logging, dashboards / live status, event logs
- **reconciliation**, archiving, and the activity-log or cadence runs themselves
- compliance-**guard** toggling, and commit / push / release *mechanics* as such

Keep the **substance** of what was decided, built, analysed, or written — even when the subject is the tools themselves. In a plugin-development repo, "design the scout sub-agent" or "cadence churn metric" are real work topics; "fusion-workbench tracking & housekeeping" is not. In an end-user project, the user's own domain work is the signal and all flight / fusion / scout machinery is noise. The test: would the user name this as something they worked on? If not, drop it.

### 5. Build the recent lists — yesterday, then last 7 days

Build two lists the same way, differing only by their window. For each: filter to the log units whose date falls in the window, collect the **distinct** topics, note where each appeared (source codes + dates), and order by how active the topic was (most log units first). State plainly when a window is empty.

- **Yesterday list** — window `[yday_start, today]`. The most recent, finest-grained view: what was touched since yesterday — or, when today is Monday, since Friday — right up to now. A topic worked on today belongs here too.
- **Last-7-days list (list 1)** — window `[week_start, today]`. The broader recent view.

The yesterday window is a subset of the 7-day window, so topics overlap between the two lists. That is expected and correct: the yesterday list simply zooms in on the latest stretch.

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
**Yesterday window:** <yday_start> → <today><!-- append " (Fri–Sun collapsed)" when today is Monday -->
**Recent window:** <week_start> → <today> (7 days)
**Sources scanned:** <e.g. fusion-workbench/history (14), git (37 commits); flight-workbench: absent, scout-workbench: absent, activity-log: none>

## Topics — yesterday

<!-- window [yday_start, today]. When today is Monday, render the heading as "## Topics — yesterday (Fri–Sun)" -->

- **<topic>** — <where it showed up: source codes + dates, one line>
- **<topic>** — ...

<!-- if the window is empty: -->
_No activity since <yday_start>._

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
