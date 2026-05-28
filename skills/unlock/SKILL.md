---
description: Write a permissive .claude/settings.local.json so future Claude Code sessions in this project run without per-tool approval prompts. Useful for non-technical users who do not want to approve every Bash, Write, and Edit operation. Takes effect on next session — Claude Code reads permission settings only at startup.
allowed-tools: [Read, Write, Bash]
---

# /flight:unlock — skip permission prompts in this project

If you find yourself constantly clicking "Allow" before flight can read files, edit CLAUDE.md, or run shell commands, this skill writes a permissive `.claude/settings.local.json` for this project. After the next session starts, prompts disappear.

## Important notes

- **Takes effect on next session.** Claude Code reads permission settings at startup, not mid-session. After this skill runs, close and reopen Claude in this project for the change to apply.
- **Project-scoped.** This file lives in `./.claude/settings.local.json`. It only affects this one project. Other Claude projects are not changed.
- **Reversible.** Delete `.claude/settings.local.json` to restore the default (prompted) behavior.
- **No security risk for normal use.** It just stops the prompts; it does not give Claude any new capabilities it would not have with you clicking "Allow" each time.

## Step 1 — Confirm with the user

Before writing, briefly tell the user what will happen:

> **About to write `.claude/settings.local.json`.** This will stop the permission prompts for file reads, writes, edits, and shell commands in this project from your next session onward. Reversible by deleting the file. OK to proceed?

If the user says no, stop. If yes, continue.

## Step 2 — Write the settings file

```bash
mkdir -p ./.claude
```

Then write `./.claude/settings.local.json` with this content:

```json
{
  "permissions": {
    "allow": [
      "Read(**)",
      "Write(**)",
      "Edit(**)",
      "Bash(*)"
    ]
  }
}
```

If the file already exists, **read it first** and merge the four allow rules into the existing `permissions.allow` array, preserving any other settings the user already has. Do not overwrite blindly.

## Step 3 — Confirm

Tell the user:

> **Done. Restart Claude in this project to apply.** Permission prompts for file reads, writes, edits, and shell commands will be skipped from your next session. To turn this off later, delete `./.claude/settings.local.json`.
