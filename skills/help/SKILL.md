---
description: Explain what flight is, how to use it day-to-day, and what each slash command does. Walks the user through the workflow in plain English. Optional topic argument routes the answer (workflow / commands / files / language / style / tasks).
argument-hint: [workflow | commands | files | language | style | tasks]
allowed-tools: [Read]
---

# /flight:help — what is flight and how do I use it?

This skill teaches the user about flight. The audience is non-technical — explain plainly, no jargon dump.

If the user passed a topic argument (`/flight:help workflow`), jump to that section. Otherwise, give the short overview, then offer to go deeper on any topic.

## Short overview (default response)

> **Flight is a lightweight AI work companion.** You talk to me, I help — analyzing documents, discussing topics, drafting written outputs (analyses, summaries, plans, slide decks). Deliverables land at your project root, easy to find. User memos (quick open-task notes filed via `/flight:memo`) and the durable session record live in `flight-workbench/` — flight's internal scaffolding.
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
> - `<prefix>-<your-doc>.<ext>` at the project root — analyses, drafts, summaries, slide decks, anything flight produces for you. Default location for all user-requested deliverables.
> - `CLAUDE.md` — your memo and open-task list (in your project root). Read at every session start.
> - `flight-workbench/history/` — every session is logged here.
> - `flight-workbench/decisions/` — important choices you asked me to track.
> - `flight-workbench/memos/` — user memos filed via `/flight:memo` only (open-task notes and short reminders, not deliverables).
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
> ├── <prefix>-<your-deliverable>.md   ← documents flight produces for you (project root, default location)
> ├── .claude/settings.local.json      ← optional, written by /flight:unlock
> └── flight-workbench/                ← internal scaffolding for flight's own tracking
>     ├── history/                     ← one file per session, the durable record (auto-logged)
>     ├── decisions/                   ← important choices you asked me to track
>     ├── memos/                       ← user memos filed via /flight:memo only (open-task notes)
>     ├── archive/                     ← /flight:archive and /flight:cleanup move stuff here
>     ├── stilwerk/                    ← style profiles (professional-voice for documents, chat-voice for chat; read-only)
>     └── .flight-setup                ← marker showing when setup ran
> ```
>
> **Project root vs. workbench.** Your deliverables — analyses, drafts, summaries, slide decks, anything flight produces *for you* — sit at the project root next to `CLAUDE.md`, easy to find. `flight-workbench/` is internal scaffolding: session histories, decision records, archived items, and style profiles. You do not need to look in there day-to-day. In particular, `flight-workbench/memos/` is reserved for short user memos filed via `/flight:memo` — it is **not** where deliverables go.
>
> **Filename rule:** every file flight creates has a date-time prefix. The default format is `YYMMDD-HHMM`, like `260528-0450-meeting-notes.md` — easy to sort and find. If you want a different shape (e.g. full year, with seconds), set the env var `FLIGHT_FILE_PREFIX` to a `date(1)` strftime string (e.g. `export FLIGHT_FILE_PREFIX='%Y%m%d-%H%M%S'`).
>
> **Where to look for things:** if you cannot find something, ask me "did we talk about X?" — I always check the history folder.

## Topic: language

> **Default is English.** If you want to work in another language, just tell me — I will ask whether to switch the project's language permanently (recorded in CLAUDE.md). Once set, I respond in that language and apply the matching style profiles: a chat-voice profile for conversational replies and a professional-voice profile for documents.
>
> Two profile pairs ship with flight, for English and German: professional-voice (`professional-voice-en.yaml`, `professional-voice-de.yaml`) for documents, and chat-voice (`chat-voice-en.yaml`, `chat-voice-de.yaml`) for chat. For other languages I read the English profile, understand the intent, and apply it in your language.

## Topic: style

> **I apply one of two style profiles, depending on what I am producing.** For chat and conversational replies, I apply the chat-voice profile at `flight-workbench/stilwerk/chat-voice-<LANG>.yaml` — it keeps replies lean, direct, and to the point. For polished documents, I apply the professional-voice profile at `flight-workbench/stilwerk/professional-voice-<LANG>.yaml` — it shapes vocabulary, sentence rhythm, and register so the output reads professionally and respects your time.
>
> You usually do not need to know more. Just chat normally for a quick reply; mention "draft a one-page memo" or "produce a clean summary" when you want a polished document.

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
