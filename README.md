# flight

A lightweight AI work companion plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview). Designed for non-technical users who want a calm, capable assistant for analyzing documents, discussing topics, and producing precise written outputs — without the complexity of multi-agent orchestration.

The plugin is named **flight**; its single AI agent is named **pilot** (dispatch with `claude --agent flight:pilot`).

flight is a flightweight cousin of [fusion](https://github.com/tenzoki/fusion). Same family, much simpler.

## What flight does

- **Analyzes documents and discusses topics.** Bring a PDF, a spec, a transcript — talk it through, get a summary, draft a response.
- **Produces well-styled written outputs.** Markdown by default; also `.pptx`, `.xlsx`, `.docx`, etc. on request. Documents apply a professional-voice stylometric profile so the prose reads cleanly; conversational replies apply a chat-voice profile that keeps them lean and direct. Deliverables land at the **project root** by default (next to `CLAUDE.md`), not inside `flight-workbench/`.
- **Tracks open tasks** in your project's `CLAUDE.md` — they show up automatically every session.
- **Files decisions** when you ask (or when a discussion surfaces an insight worth keeping).
- **Logs every session** to `flight-workbench/history/`, so the conversation is durable even if you do not use git.

## What flight is NOT

- Not a code-writing assistant primarily (though it can write code on request).
- Not [fusion](https://github.com/tenzoki/fusion). No orchestrator, no Turn loops, no Coherence checks, no compliance guard, no sub-agent dispatch.
- Not silent. Flight asks before destructive operations.

## Quick start

```bash
# In Claude Code, add the marketplace and install flight
/plugin marketplace add tenzoki/claude-plugins
/plugin install flight@tenzoki-plugins

# In any project folder where you want to work
/flight:start
```

That's it. `/flight:start` creates a `flight-workbench/` folder, copies the style profiles, initializes `CLAUDE.md` (if missing), and tells you what's on your plate.

After that, just talk. When done, `/flight:land` closes the session cleanly.

## The seven slash commands

| Command | What it does |
|---|---|
| `/flight:start` | Set up or refresh the workbench, read CLAUDE.md, show open tasks |
| `/flight:land` | Close the session — summary to history, compact CLAUDE.md, carry forward unresolved tasks |
| `/flight:memo <text>` | Capture an open task (or a longer memo) |
| `/flight:cleanup` | Strip closed/stale tasks from CLAUDE.md, archive the strippings |
| `/flight:archive` | Move old workbench files into a timestamped archive bundle |
| `/flight:unlock` | Write a permissive permissions file so future sessions skip approval prompts |
| `/flight:help` | Explainer. Optional topic: workflow, commands, files, language, style, tasks |

## What gets created in your project

```
your-project/
├── CLAUDE.md                        ← your memo file + flight conventions
├── <prefix>-<your-deliverable>.md   ← documents flight produces for you (project root, default location)
├── .claude/settings.local.json      ← optional, written by /flight:unlock
└── flight-workbench/                ← internal scaffolding for flight's own tracking
    ├── history/                     ← one file per session (auto-logged)
    ├── decisions/                   ← important choices you tracked
    ├── memos/                       ← user memos filed via /flight:memo only (not deliverables)
    ├── archive/                     ← /flight:cleanup and /flight:archive move here
    ├── stilwerk/                    ← style profiles (professional-voice for documents, chat-voice for chat; read-only)
    └── .flight-setup                ← setup marker (when/where)
```

Your deliverables — analyses, summaries, drafts, slide decks, anything flight produces for you — sit at the project root next to `CLAUDE.md`, easy to find. `flight-workbench/` is internal scaffolding for flight's own tracking; you do not need to look in there day-to-day.

Every file flight creates carries a date-time prefix: `<prefix>-<name>.<ext>`. The default prefix renders as `YYYY-MM-DD_HH-MM` (e.g. `2026-05-28_04-50`). You can override it by setting the environment variable `FLIGHT_FILE_PREFIX` to a `date(1)` strftime string — e.g. `export FLIGHT_FILE_PREFIX='%Y%m%d-%H%M%S'` for full-year + seconds precision. Default keeps existing projects working; change it only on a clean project, or you will get inconsistent sort order.

## Language

Default is English. If you work in another language, flight asks once whether to switch the project's language permanently (recorded in `CLAUDE.md`). flight ships professional-voice style profiles (for documents) and chat-voice profiles (for conversational replies) in English and German; for other languages, it reads the English profile and applies the same intent in the target language.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) v2.0.12 or higher
- That's it. No git, no Node, no Python required for the core skills. (Producing `.pptx` / `.xlsx` etc. uses Python libraries on request, but you do not need to install them upfront.)

## License

MIT. See [LICENSE](LICENSE).
