---
description: Close the current flight session. Writes a session summary to flight-workbench/history/<session>-session.md and carries any unresolved tasks forward into flight-workbench/memos/tasks-<user>.md. Does not touch CLAUDE.md — that file is shared with other tools and holds no flight tracking data. Run this when you are done for the day or session — it leaves the project in a clean state for next time.
allowed-tools: [Read, Write, Edit, Bash, AskUserQuestion]
---

# /flight:land — close the session

Use this when you are done working. Land does two things:

1. **Finalizes the session history** — adds a summary block to today's `flight-workbench/history/<TS>-session.md`.
2. **Carries forward unresolved tasks** — any open task that surfaced during the session but was not finished gets added to `flight-workbench/memos/tasks-<user>.md`.

Land does **not** edit `CLAUDE.md`. CLAUDE.md is auto-loaded into every session and is shared with other tools (e.g. fusion); flight stores no tasks, memos, or session log there, so there is nothing for land to compact. All flight tracking data lives under `flight-workbench/`.

After landing, the project is ready for the next session.

## Step 0 — Confirm

Brief the user on what will happen:

> **About to land this session.** I will:
> 1. Summarize this session into today's history file.
> 2. Add any unresolved tasks from this session to your open-task list.
>
> OK to proceed? (yes / cancel)

- **yes** — full landing (both steps).
- **cancel** — exit without doing anything.

## Step 1 — Find the active session history file

Locate the most recent file in `flight-workbench/history/` matching `*-session.md`. That is the active session.

If multiple session files share today's date, pick the newest (latest mtime). If none exists, warn the user and offer to create one before continuing.

## Step 2 — Identify and carry forward unresolved tasks

Determine the OS user: `echo "$USER"`.

Read the session history file. Scan the `## Log` section for any task-like entries that surfaced during the session — phrases like "TODO", "follow up", "we need to", "later", or tasks added via `/flight:memo` during this session. Tasks already added via `/flight:memo` are in `flight-workbench/memos/tasks-$USER.md`; what you are looking for here is tasks **discussed but not yet recorded**.

For each candidate unresolved task, ask the user (group several into one `AskUserQuestion` if there are many):

> **Carry forward this task?** "<task description>"
>
> - **Yes, add to open tasks** (Recommended)
> - **No, drop it** — it was a passing thought
> - **Already done** — do not carry forward

For each "Yes", append the task to `flight-workbench/memos/tasks-$USER.md` using the `/flight:memo` Step 2a procedure (date-prefixed line item; create the file from its header if missing).

## Step 3 — Write the session summary to history

Append a `## Summary` section to the active session history file. Get the `**Ended:**` time from `date +"%Y-%m-%d %H:%M"` — run it in the shell and use the output verbatim; never write a time from your own sense of "now" (your clock is UTC and would be off by the local offset).

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

## Step 4 — Final report

> **Session landed.** History finalized, X unresolved tasks carried forward.
>
> **Details:**
> - Session history: `flight-workbench/history/<filename>`
> - Open tasks now: N (`flight-workbench/memos/tasks-<user>.md`)
>
> Have a good one. Next time you start, `/flight:start` will pick up where we left off.

## What this skill does NOT do

- **Never edits CLAUDE.md.** Flight keeps no tasks, memos, or session log there.
- Does not commit anything to git (flight does not assume git use).
- Does not delete the workbench or any history files.
- Does not run `/flight:cleanup` automatically — task hygiene is a separate explicit action.
