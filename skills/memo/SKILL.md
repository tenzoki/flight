---
description: Capture an open task or a longer memo. Open tasks go into flight-workbench/memos/tasks-<user>.md; longer memos go into flight-workbench/memos/memos-<user>.md (one file per OS user, like fusion). Nothing is written to CLAUDE.md — that file is shared with other tools. Use whenever the user says "remember this", "add a task", "note that", or hands you something to do later. Takes optional text as argument; if no text is given, ask the user what to record.
argument-hint: [task text or longer memo]
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# /flight:memo — record an open task or a memo

Capture an open task or a memo into the per-user files under `flight-workbench/memos/`. When the user says "remember", "add a task", "we need to", "later", or anything similar, use this skill.

**Never write tasks or memos into `CLAUDE.md`.** CLAUDE.md is auto-loaded into every Claude Code session and is shared with other tools (e.g. fusion) whose own CLAUDE.md upkeep would prune or overwrite anything flight stores there. All flight tracking data lives under `flight-workbench/`, which other tools never touch.

## Per-user files

Determine the OS user first: `echo "$USER"`. Two files, both under `flight-workbench/memos/`:

- **`flight-workbench/memos/tasks-$USER.md`** — the open-task checklist. A living list: items are added here, pruned by `/flight:cleanup`, carried forward by `/flight:land`, and surfaced at `/flight:start`.
- **`flight-workbench/memos/memos-$USER.md`** — the memo log. Append-only, dated `##` sections, verbatim captures (the fusion memo model).

Create either file if missing (see headers below). Always `mkdir -p ./flight-workbench/memos` first.

## Step 1 — Determine what the user wants to record

If text was passed as an argument to `/flight:memo`, use it verbatim. Otherwise, ask:

> What should I record?

When the user replies, decide which of three shapes the input is:

1. **An open task** — actionable, short ("call Stefan about the v2 schema", "draft a reply to the auditor"). Default for short imperative input.
2. **A longer memo** — context, background, a reference list, anything that is not a single task. Default if the input is more than ~2 sentences or has multiple paragraphs.
3. **Ambiguous** — ask the user via `AskUserQuestion` whether to file it as an open task or as a memo.

## Step 2a — File as an open task (tasks-$USER.md)

Read `./flight-workbench/memos/tasks-$USER.md`. If it does not exist, create it with this header and nothing else:

```markdown
# Open tasks — <username>

<!-- flight open-task checklist. One file per OS user. Added via /flight:memo, pruned via /flight:cleanup, carried forward by /flight:land, surfaced at /flight:start. Not stored in CLAUDE.md (shared with other tools). -->

(No open tasks yet. Use /flight:memo <task> to add one.)
```

Append the new task as a markdown list item with a date prefix:

```
- [<prefix>] <task text>
```

Get the timestamp from `date +"${FLIGHT_FILE_PREFIX:-%Y-%m-%d_%H-%M}"` (env var `FLIGHT_FILE_PREFIX` overrides the default; default renders as `YYYY-MM-DD_HH-MM`). If the file still holds the placeholder line `(No open tasks yet...)`, remove that line first.

After updating, confirm to the user:

> **Added to your open tasks.** "<task text>"
>
> You currently have N open tasks. Type `/flight:cleanup` any time to remove ones that are no longer relevant.

## Step 2b — File as a longer memo (memos-$USER.md)

Read `./flight-workbench/memos/memos-$USER.md`. If it does not exist, create it with this header and nothing else:

```markdown
# Memos — <username>
```

Append the memo as a single dated `##` section at the end of the file (leave one blank line before it). Capture the user's content **verbatim** — do not rewrite it in your own words.

Timestamp: `date +"%Y-%m-%d %H:%M"`.

```markdown
## YYYY-MM-DD HH:MM — <topic>

<memo body, verbatim from the user>

Refs: <optional — path(s) to related files; drop this line if there is nothing to point to>
```

Keep memos concise. If a memo would run longer than ~15 lines, it probably belongs in `flight-workbench/decisions/` or as a deliverable at the project root, not in the memo log. Never reorder or rewrite prior memos.

Confirm to the user:

> **Memo saved.** `flight-workbench/memos/memos-<user>.md` (topic: "<topic>")
>
> Want me to also add a one-line open task pointing at it, so it surfaces at next session start? (yes/no)

If yes, add this to `tasks-$USER.md` following Step 2a:

```
- [<prefix>] Follow up on memo: <topic> (see flight-workbench/memos/memos-<user>.md)
```

## Step 3 — Append to the session history

Append a one-line entry to today's session history file (`flight-workbench/history/<latest-TS>-session.md`, find the most recent one) under the `## Log` section:

```
- <HH:MM> memo: added open task "<task text>"
```

or

```
- <HH:MM> memo: filed memo "<topic>" in flight-workbench/memos/memos-<user>.md
```

This keeps the history file as a complete record of what was discussed and produced.

## What this skill does NOT do

- **Never writes to CLAUDE.md.** Tasks go to `tasks-<user>.md`, memos to `memos-<user>.md`.
- Does not delete or modify existing tasks (use `/flight:cleanup` for that).
- Does not reorder or rewrite existing memos.
- Does not run inside long-running work — it is a quick capture step.
