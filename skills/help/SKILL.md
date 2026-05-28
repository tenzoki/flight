---
name: help
description: Explain what flight is, how to use it day-to-day, and what each slash command does. Walks the user through the workflow in plain English. Optional topic argument routes the answer (workflow / commands / files / language / style / tasks).
allowed-tools: Read
---

# /flight:help — what is flight and how do I use it?

This skill teaches the user about flight. The audience is non-technical — explain plainly, no jargon dump.

If the user passed a topic argument (`/flight:help workflow`), jump to that section. Otherwise, give the short overview, then offer to go deeper on any topic.

## Short overview (default response)

> **Flight is a lightweight AI work companion.** You talk to me, I help — analyzing documents, discussing topics, drafting written outputs (memos, summaries, decisions, plans). Everything you ask me to remember lives in your project folder, so the next session picks up where we left off.
>
> **Day-to-day flow:**
>
> 1. Open Claude in a folder where you want to work.
> 2. Type `/flight:start` once to set things up.
> 3. Just talk to me — analyze a document, draft something, discuss an idea.
> 4. When you are done, type `/flight:land` to close the session cleanly.
>
> **The key files:**
>
> - `CLAUDE.md` — your memo and open-task list (in your project root). Read at every session start.
> - `flight-workbench/history/` — every session is logged here.
> - `flight-workbench/decisions/` — important choices you asked me to track.
> - `flight-workbench/memos/` — longer notes you saved.
>
> **The slash commands:**
>
> | Command | Use it when |
> |---|---|
> | `/flight:start` | First time in a project, or to refresh the setup |
> | `/flight:land` | Closing the session — summary + cleanup |
> | `/flight:memo` | Capture an open task or a longer note |
> | `/flight:cleanup` | Trim closed/stale tasks from CLAUDE.md |
> | `/flight:archive` | Move old files into the archive folder |
> | `/flight:unlock` | Stop the permission prompts (one-time per project) |
> | `/flight:help` | This. With an optional topic — try `/flight:help workflow` |
>
> Want more detail on any of these? Tell me, or run `/flight:help <topic>`. Topics: workflow / commands / files / language / style / tasks.

## Topic: workflow

> **A typical flight session looks like this:**
>
> 1. **Start.** Open Claude in your project folder. Type `/flight:start`. I will read your CLAUDE.md, show you any open tasks, and tell you what we did last time.
> 2. **Work.** Just talk to me. Examples:
>    - "Analyze this PDF I'm about to share."
>    - "Draft a one-page summary of <topic> for <audience>."
>    - "Help me think through whether to do X or Y."
>    - "Remember that I prefer concise output." (I will offer to file this as a project memo.)
> 3. **Track decisions and tasks as we go.** When something important is decided, I will offer to file it under `flight-workbench/decisions/`. When you mention a task, I will offer to add it to your open-task list.
> 4. **Land.** When you are done for the day or session, type `/flight:land`. I will write a session summary, carry forward any unresolved tasks, and tidy up your CLAUDE.md.

## Topic: commands

> **The seven slash commands:**
>
> **`/flight:start`** — Sets up the workbench (creates `flight-workbench/` and copies the style profiles) and reads CLAUDE.md. Safe to re-run any time; it never overwrites your content.
>
> **`/flight:land`** — Closes the session: writes a summary to history, carries unresolved tasks forward into CLAUDE.md, and compacts CLAUDE.md (with your approval) by adding new learnings, updating stale memos, and pruning obsolete entries.
>
> **`/flight:memo <text>`** — Quick capture. Short imperative ("call Stefan about the schema") becomes an open task in CLAUDE.md. Longer text becomes a memo file under `flight-workbench/memos/`. If unsure, I will ask.
>
> **`/flight:cleanup`** — Trims your open-task list. Removes tasks you have marked closed (e.g. with `[x]`), and asks you about each task that looks stale or redundant. Strippings go to `flight-workbench/archive/` so nothing is lost.
>
> **`/flight:archive`** — Moves old workbench files (history, memos, decisions) into a timestamped archive bundle. Pre-defined scopes (recent / mid / deep) or describe in your own words ("everything older than April").
>
> **`/flight:unlock`** — Writes a permissions file so you stop getting "Allow Bash? Allow Write?" prompts in this project. Takes effect on next session.
>
> **`/flight:help`** — This explainer.

## Topic: files

> **Where flight keeps things:**
>
> ```
> your-project/
> ├── CLAUDE.md                        ← your memo file + flight conventions (read every session)
> ├── .claude/settings.local.json      ← optional, written by /flight:unlock
> └── flight-workbench/
>     ├── history/                     ← one file per session, the durable record
>     ├── decisions/                   ← important choices you asked me to track
>     ├── memos/                       ← longer notes filed via /flight:memo
>     ├── archive/                     ← /flight:archive and /flight:cleanup move stuff here
>     ├── stilwerk/                    ← the professional-voice style profiles (do not edit)
>     └── .flight-setup                ← marker showing when setup ran
> ```
>
> **Filename rule:** every file flight creates has a date-time prefix in the format `YYMMDD-HH-MM`, like `260528-04-50-meeting-notes.md`. That makes them easy to sort and find.
>
> **Where to look for things:** if you cannot find something, ask me "did we talk about X?" — I always check the history folder.

## Topic: language

> **Default is English.** If you want to work in another language, just tell me — I will ask whether to switch the project's language permanently (recorded in CLAUDE.md). Once set, I respond in that language and apply the matching professional-voice style profile.
>
> Supported style profiles ship with flight: English (`professional-voice-en.yaml`) and German (`professional-voice-de.yaml`). For other languages I read the English profile, understand the intent, and apply it in your language.

## Topic: style

> **For prose generation, I apply the professional-voice style profile** at `flight-workbench/stilwerk/professional-voice-<LANG>.yaml`. This is a stylometric guide — it shapes vocabulary, sentence rhythm, and register so the output reads professionally and respects the reader's time.
>
> You usually do not need to know more. If you want short conversational chat, just ask in chat. If you want a polished document, mention "draft a one-page memo" or "produce a clean summary" and the style profile applies.

## Topic: tasks

> **Open tasks live in CLAUDE.md, in the `## Open tasks` section.** They show up automatically every time you `/flight:start`.
>
> **Three ways tasks get there:**
>
> 1. You run `/flight:memo <task>`.
> 2. You tell me in chat ("can we add X to my list?") — I will offer to file it.
> 3. `/flight:land` carries unresolved tasks forward from the session you just closed.
>
> **Three ways tasks leave:**
>
> 1. You mark them done in CLAUDE.md (start the line with `- [x]`), then run `/flight:cleanup`.
> 2. `/flight:cleanup` flags stale or redundant tasks and asks you what to do.
> 3. You edit CLAUDE.md directly — it is just a text file, you own it.
