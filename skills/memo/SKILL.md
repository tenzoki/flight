---
description: Capture an open task or a longer memo. Open tasks go into CLAUDE.md (the user's memo file) — that is the primary use, far more important than fusion's memo. Longer free-form memos can also be filed under flight-workbench/memos/. Use whenever the user says "remember this", "add a task", "note that", or hands you something to do later. Takes optional text as argument; if no text is given, ask the user what to record.
argument-hint: [task text or longer memo]
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# /flight:memo — record an open task or a memo

The primary purpose is **open-task tracking**. When the user says "remember", "add a task", "we need to", "later", or anything similar, use this skill to record it. Open tasks live in `CLAUDE.md`'s **Open tasks** section so they show up automatically at every `/flight:start`.

A secondary use is filing longer-form memos (richer than a task line) under `flight-workbench/memos/`.

## Step 1 — Determine what the user wants to record

If text was passed as an argument to `/flight:memo`, use it verbatim. Otherwise, ask:

> What should I record?

When the user replies, decide which of three shapes the input is:

1. **An open task** — actionable, short ("call Stefan about the v2 schema", "draft a reply to the auditor"). Default for short imperative input.
2. **A longer memo** — context, background, a reference list, anything that is not a single task. Default if the input is more than ~2 sentences or has multiple paragraphs.
3. **Ambiguous** — ask the user via `AskUserQuestion` whether to file as an open task in CLAUDE.md or as a longer memo under `memos/`.

## Step 2a — File as an open task (CLAUDE.md)

Read `./CLAUDE.md`. Locate the `## Open tasks` section.

Append the new task as a markdown list item with a date prefix:

```
- [<prefix>] <task text>
```

Get the timestamp from `date +"${FLIGHT_FILE_PREFIX:-%y%m%d-%H%M}"` (env var `FLIGHT_FILE_PREFIX` overrides the default; default renders as `YYMMDD-HHMM`). If the **Open tasks** section starts with the placeholder text `(No open tasks yet...)`, remove that line first.

If the `## Open tasks` section does not exist (e.g. CLAUDE.md was edited and the heading was removed), add it just before `## Project memos`, or at the end of the file if `## Project memos` is also missing.

After updating, confirm to the user:

> **Added to your open tasks.** "<task text>"
>
> You currently have N open tasks. Type `/flight:cleanup` any time to remove ones that are no longer relevant.

## Step 2b — File as a longer memo (flight-workbench/memos/)

Generate a short, descriptive filename slug from the memo's first line or topic (kebab-case, lowercase, ASCII).

Write the memo to `./flight-workbench/memos/<prefix>-<slug>.md` (where `<prefix>` comes from `date +"${FLIGHT_FILE_PREFIX:-%y%m%d-%H%M}"`):

```markdown
# <derived title>

**Filed:** <YYYY-MM-DD HH:MM>

<memo body, verbatim from the user>
```

Confirm to the user:

> **Memo saved.** `flight-workbench/memos/<prefix>-<slug>.md`
>
> Want me to also add a one-line pointer to this in your open tasks (so it shows up at next session start)? (yes/no)

If yes, add an entry like:

```
- [<prefix>] Follow up on memo: <slug> (see flight-workbench/memos/<prefix>-<slug>.md)
```

to CLAUDE.md's **Open tasks** section, following the same rules as Step 2a.

## Step 3 — Append to the session history

Append a one-line entry to today's session history file (`flight-workbench/history/<latest-TS>-session.md`, find the most recent one) under the `## Log` section:

```
- <HH:MM> memo: added open task "<task text>"
```

or

```
- <HH:MM> memo: filed memo at flight-workbench/memos/<filename>
```

This keeps the history file as a complete record of what was discussed and produced.

## What this skill does NOT do

- Does not delete or modify existing tasks (use `/flight:cleanup` for that).
- Does not compact CLAUDE.md (that is `/flight:land`).
- Does not run inside long-running work — it is a quick capture step.
