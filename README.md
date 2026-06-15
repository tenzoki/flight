# flight

A lightweight AI work companion plugin for [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview). Designed for non-technical users who want a calm, capable assistant for analyzing documents, discussing topics, and producing precise written outputs — without the complexity of multi-agent orchestration.

The plugin is named **flight**; its single AI agent is named **pilot** (dispatch with `claude --agent flight:pilot`).

flight is a flightweight cousin of [fusion](https://github.com/tenzoki/fusion). Same family, much simpler.

## What flight does

- **Analyzes documents and discusses topics.** Bring a PDF, a spec, a transcript — talk it through, get a summary, draft a response.
- **Produces well-styled written outputs.** Markdown by default; also `.pptx`, `.xlsx`, `.docx`, etc. on request. Documents apply a professional-voice stylometric profile so the prose reads cleanly; conversational replies apply a chat-voice profile that keeps them lean and direct. Deliverables land at the **project root** by default (next to `CLAUDE.md`), not inside `flight-workbench/`.
- **Tracks open tasks** in `flight-workbench/memos/tasks-<user>.md` — they show up automatically every session. (Not in `CLAUDE.md`, which is shared with other tools.)
- **Files decisions** when you ask (or when a discussion surfaces an insight worth keeping).
- **Logs every session** to `flight-workbench/history/`, so the conversation is durable even if you do not use git.

## What flight is NOT

- Not a code-writing assistant primarily (though it can write code on request).
- Not [fusion](https://github.com/tenzoki/fusion). No orchestrator, no Turn loops, no Coherence checks, no compliance guard, no sub-agent dispatch.
- Not silent. Flight asks before destructive operations.

## Quick start (recommended — one line, no git)

In your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/tenzoki/flight/main/install.sh | bash
```

This downloads flight over plain HTTPS into `~/.flight` and installs a `flight`
launcher. No git, no SSH, no Claude Code marketplace. Then, in any project folder:

```bash
flight          # starts Claude Code with the pilot agent loaded
/flight:start   # sets up this project's workbench
```

- **Update:** `flight --update` (or re-run the one-liner above).
- **Uninstall:** `flight --uninstall`.
- **Where it lives:** `flight --where` (prints the install dir).

`/flight:start` creates a `flight-workbench/` folder, copies the style profiles, initializes `CLAUDE.md` (if missing), and tells you what's on your plate.

### Where flight installs

The one-line installer writes to exactly two places — both in your home folder, nothing system-wide and nothing inside Claude Code's plugin cache:

```
~/.local/bin/flight     the `flight` command (a thin launcher script)
~/.flight/              the plugin files: .claude-plugin/, agents/, skills/,
                        templates/, stilwerk/, README, LICENSE
```

The launcher is one line — `claude --plugin-dir ~/.flight --agent flight:pilot "$@"` — so every run loads the plugin straight from `~/.flight`. That is why update and uninstall are reliable: there is no cache to get out of sync. `flight --where` prints the plugin path any time.

Both locations are overridable with environment variables before installing:

- `FLIGHT_HOME` — where the plugin files go (default `~/.flight`)
- `FLIGHT_BIN` — where the `flight` launcher goes (default `~/.local/bin`)

To remove flight completely: `flight --uninstall` (which is just `rm -rf ~/.flight` plus removing the launcher). Claude Code's own `~/.claude/` directory is never touched.

### Alternative: Claude Code marketplace

If you prefer the built-in plugin system (note: it uses git, which can fail when your git is configured for SSH):

```bash
/plugin marketplace add tenzoki/claude-plugins
/plugin install flight@tenzoki-plugins
```

After that, just talk. When done, `/flight:land` closes the session cleanly.

## The nine slash commands

| Command | What it does |
|---|---|
| `/flight:start` | Set up or refresh the workbench, read CLAUDE.md, show open tasks |
| `/flight:land` | Close the session — summary to history, carry forward unresolved tasks |
| `/flight:memo <text>` | Capture an open task (or a longer memo) |
| `/flight:log-activity` | Scan project activity into `activity-log-<user>.md` (reuses fusion's log if present) |
| `/flight:cadence` | Analyse logs into two topic lists — recent (7 days) + recurring by churn — at `flight-workbench/cadence-<user>.md` |
| `/flight:cleanup` | Strip closed/stale tasks from your task list, archive the strippings |
| `/flight:archive` | Move old workbench files into a timestamped archive bundle |
| `/flight:unlock` | Write a permissive permissions file so future sessions skip approval prompts |
| `/flight:help` | Explainer. Optional topic: workflow, commands, files, language, style, tasks |

## What gets created in your project

```
your-project/
├── CLAUDE.md                        ← project language + flight conventions
├── <prefix>-<your-deliverable>.md   ← documents flight produces for you (project root, default location)
├── .claude/settings.local.json      ← optional, written by /flight:unlock
└── flight-workbench/                ← internal scaffolding for flight's own tracking
    ├── history/                     ← one file per session (auto-logged)
    ├── decisions/                   ← important choices you tracked
    ├── memos/                       ← your open tasks (tasks-<user>.md) + memos (memos-<user>.md), via /flight:memo only
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
