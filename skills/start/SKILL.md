---
description: Initialize the flight workbench in the current project directory. Creates ./flight-workbench/ with subfolders (history, decisions, memos, archive, stilwerk), copies the stylometric profiles, initializes CLAUDE.md (the user's memo and instruction file) from the template if missing, then reads CLAUDE.md and reports any open tasks to the user. Run once per project, or re-run any time to refresh the stilwerk profiles and verify the layout. Idempotent — never overwrites user content.
allowed-tools: [Read, Write, Bash, Edit, AskUserQuestion]
---

# /flight:start — initialize a flight project

Run this once in any project folder to set up the flight workbench, or re-run it any time to refresh the style profiles and verify the layout.

The skill is **idempotent** and **non-destructive** — it never overwrites CLAUDE.md if one already exists, and never deletes files.

## Step 0 — Confirm where you are

```bash
pwd
```

Report the path to the user. The workbench will be created at `./flight-workbench/` relative to this directory. If the user wanted to start in a different folder, they should cancel and `cd` there first.

## Step 1 — Locate the flight plugin's source files

This skill needs to copy two files from the plugin's `stilwerk/` directory into the project's workbench: `professional-voice-en.yaml` and `professional-voice-de.yaml`.

The plugin's base directory for this skill is provided by Claude Code at invocation time (look for the line "Base directory for this skill:" in this prompt's context). From that path, the plugin root is `dirname(dirname(base_dir))` — strip the trailing `/skills/start`. The stilwerk source files are at `<plugin-root>/stilwerk/`.

If you cannot determine the plugin root, fall back to: try `$FLIGHT_PLUGIN_ROOT/stilwerk/`; if unset, search `~/.claude/plugins/cache/tenzoki-plugins/flight/*/stilwerk/` and pick the newest version. If all three fail, warn the user that the style profiles could not be installed; the workbench is still usable, but `/flight:start` should be re-run from a properly installed plugin to get the profiles.

## Step 2 — Create the workbench

```bash
mkdir -p ./flight-workbench/history ./flight-workbench/decisions ./flight-workbench/memos ./flight-workbench/archive ./flight-workbench/stilwerk
```

`mkdir -p` is safe to rerun — existing directories are untouched, missing ones are added.

## Step 3 — Install the style profiles

Copy both YAML profiles from `<plugin-root>/stilwerk/` into `./flight-workbench/stilwerk/`. Always overwrite — the source-of-truth is the plugin version, so a refresh on /flight:start re-installs the latest. Use:

```bash
cp "<plugin-root>/stilwerk/professional-voice-en.yaml" ./flight-workbench/stilwerk/
cp "<plugin-root>/stilwerk/professional-voice-de.yaml" ./flight-workbench/stilwerk/
```

Replace `<plugin-root>` with the path resolved in Step 1. After the copy, list `./flight-workbench/stilwerk/` and confirm both files are present.

## Step 4 — Write the setup marker

```bash
printf '{"setup_at":"%s","setup_pwd":"%s","plugin_version":"%s"}\n' "$(date +%Y-%m-%dT%H:%M:%S%z)" "$(pwd -P)" "$(grep '"version"' "<plugin-root>/.claude-plugin/plugin.json" | head -1 | sed -E 's/.*"version": *"([^"]+)".*/\1/')" > ./flight-workbench/.flight-setup
```

The plugin version is read from `<plugin-root>/.claude-plugin/plugin.json` so the marker always reflects what version of flight set up this project. Replace `<plugin-root>` with the path resolved in Step 1. Harmless to overwrite on re-runs.

## Step 5 — Initialize CLAUDE.md (only if missing)

Check if `./CLAUDE.md` exists.

**If it does NOT exist:** copy the template from the plugin at `<plugin-root>/templates/CLAUDE.md.template` to `./CLAUDE.md`. The template is the system-prompt-extension that makes the default Claude session in this project behave as flight; without it, future sessions will not know about flight's conventions.

**If it already exists:** read it. Do NOT overwrite. The user has already curated content here. Report to the user: "Found existing CLAUDE.md — keeping it as is."

## Step 6 — Create today's session history file

Get the current timestamp using the configurable prefix format (env var `FLIGHT_FILE_PREFIX`, defaulting to `%y%m%d-%H%M`). Create the session history file:

```bash
TS="$(date +"${FLIGHT_FILE_PREFIX:-%y%m%d-%H%M}")"
cat > "./flight-workbench/history/${TS}-session.md" <<EOF
# Session ${TS}

**Started:** $(date +%Y-%m-%d\ %H:%M)
**Status:** active

## Log

(Conversation log — flight appends notable exchanges, decisions reached, and files produced.)
EOF
```

This file will be appended to throughout the session and finalized at `/flight:land`.

## Step 7 — Read CLAUDE.md and summarize

Read `./CLAUDE.md` and extract:

1. The **Language** line (default English).
2. The **Open tasks** section. Count the open tasks. If any exist, list them.
3. Any session entries under **Recent sessions** (newest first; show up to 3).

## Step 8 — Report to the user

Output a short, action-first summary. Lead with **what the user can do next**:

> **Flight is ready. Tell me what you'd like to work on, or pick from the open tasks below.**
>
> **Open tasks (N):**
> - <task 1>
> - <task 2>
>
> **Project language:** <lang>
>
> **Last sessions:**
> - <recent session line 1>
> - <recent session line 2>
>
> **Details:** Workbench at `./flight-workbench/`; CLAUDE.md at project root; style profiles installed under `flight-workbench/stilwerk/`; this session's history at `flight-workbench/history/<TS>-session.md`. Type `/flight:help` for a tour.

If there are no open tasks, say so explicitly and prompt for input:

> **Flight is ready. No open tasks recorded — what would you like to work on?**
>
> Project language: <lang>. Type `/flight:help` if you want a tour of what flight can do.

## What this skill does NOT do

- Does not modify an existing `CLAUDE.md`.
- Does not delete any existing files in `flight-workbench/`.
- Does not configure git, set up hooks, or install dependencies.
- Does not require the user to be technical — every step works without git, node, or python.
