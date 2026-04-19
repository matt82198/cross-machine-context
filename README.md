# cross-machine-context

Portable Claude Code orchestration config for Windows — CLAUDE.md rules, memory files, settings, and skills live in a git repo and follow you to every machine.

***THIS IS PURELY AN EXAMPLE OF HOW TO CONFIGURE CLAUDE TO UTILIZE A MORE TOKEN EFFECICENT ORCHESTRATION AND PERSITANCE LAYER, YOU NEED TO BUILD YOUR MEMORIES, BEHAVIORS, ETC FROM SCRATCH. THE README FULLY WALKS THROUGH THIS.***

---

## The Problem

Claude Code's power comes from its context: your `CLAUDE.md` orchestration rules, the memory files that build your developer profile over time, your model routing decisions, your settings. All of it lives in `~/.claude/` — a local directory that vanishes the moment you switch machines, rebuild, or hand off a workflow to a second box.

Every new machine means starting over: re-teaching Claude your preferences, re-establishing your TDD pipeline, re-wiring your model routing. And if you're running agentic sessions that write back to memory files, that state is silently stuck on whichever machine ran the session.

This repo solves that by turning `~/.claude/` into a git-tracked directory junction. Claude Code writes directly into the repo. You push when you want to sync.

---

## What You Get

- **Portable CLAUDE.md** — your orchestration rules (model routing, parallelism defaults, TDD pipeline, domain-scoped docs) travel with you
- **Portable memory files** — developer profile, feedback corrections, and project state accumulate in git instead of dying on a single machine
- **Model routing baked in** — Opus orchestrates only; Sonnet implements; Haiku reads, fetches, and summarizes. The rule is enforced at the config layer, not per-session
- **Parallelism-first defaults** — sub-agents fan out concurrently by default; sequential spawning is the exception, not the norm
- **TDD pipeline** — tests before implementation, failing tests spawn dedicated bugfix agents, no green = no merge
- **One-command new machine setup** — clone the repo, run `bootstrap.ps1`, done
- **Existing machine migration** — `swap-to-junction.ps1` merges your live `~/.claude` into the repo, then replaces it with a junction

---

## Quick Start

### New machine (no existing Claude config)

```powershell
# 1. Clone the repo
git clone https://github.com/your-username/cross-machine-context.git ~/cross-machine-context

# 2. Run bootstrap — creates the junction and installs dotclaude.json
pwsh ~/cross-machine-context/scripts/bootstrap.ps1

# 3. Start Claude Code — if auth fails, re-authenticate
claude /logout
claude
```

### Existing machine (you already have a `~/.claude`)

Close all Claude Code processes first, then:

```powershell
pwsh ~/cross-machine-context/scripts/swap-to-junction.ps1
```

This merges your live `~/.claude` into the repo copy, backs up the original directory, and creates the junction. Your previous `~/.claude` is preserved at `~/.claude.backup-<timestamp>` until you verify everything works.

---

## What's Inside

```
cross-machine-context/
  .gitignore                      OS noise + machine-local cache dirs excluded
  README.md                       This file
  LICENSE                         MIT
  dotclaude.json                  Synced copy of ~/.claude.json (auth tokens excluded — copy manually)

  dot-claude/                     Junctioned to ~/.claude on each machine
    CLAUDE.md                     Agentic orchestration rules (model routing, TDD, parallelism, domain docs)
    settings.json                 Claude Code settings (thinking on, high effort, auto permissions, plugin scaffold)
    projects/                     Per-project memory files written back by Claude during sessions
      */memory/                   Memory files for each project (user profile, feedback, project state)

  scripts/
    bootstrap.ps1                 New machine setup: create junction, install dotclaude.json
    swap-to-junction.ps1          Existing machine: merge live ~/.claude, then replace with junction
    sync.ps1                      Manual sync: commit current state and push to GitHub

  examples/
    memory_user_example.md        Example user profile memory file
    memory_feedback_example.md    Example feedback/correction memory file
    memory_project_example.md     Example project state memory file
```

---

## Usage Workflows

### Day-to-day (junction already installed)

Once the junction is in place, you do not need to copy anything. Edits to files in `dot-claude/` are immediately live in `~/.claude/` and vice versa — they are the same directory.

After a session where something meaningful changed (new memory file written, settings edited, new CLAUDE.md added to a domain):

```powershell
pwsh ~/cross-machine-context/scripts/sync.ps1
```

`sync.ps1` does a `git add -A`, commits with a timestamp + hostname, and pushes. If the junction is already installed, it skips the `robocopy` step since the data is already live in the repo.

### Pulling updates on another machine

```powershell
cd ~/cross-machine-context
git pull
```

Because `~/.claude` is a junction pointing at `dot-claude/`, the pull immediately takes effect — no copy step needed.

### Editing orchestration rules

Edit `dot-claude/CLAUDE.md` directly. Since the junction is active, Claude Code sees the change immediately in the next session. Run `sync.ps1` afterward to push the change.

### Adding domain-scoped CLAUDE.md files

Per the orchestration rules in `dot-claude/CLAUDE.md`, each subsystem or bounded context in a project gets its own `CLAUDE.md`. These live inside the project repo, not here. This repo carries the global rules that apply to every session on every machine.

### Adding memory files

Memory files live at `dot-claude/projects/<project-slug>/memory/`. Claude writes these during sessions when instructed. The `examples/` directory has annotated templates showing the expected structure for user, feedback, and project memory files.

---

## Security

> **Never commit credentials, tokens, or secrets to this repo.**

The repo is designed to be **private**. Keeping it private is what makes storing session state and config in git safe. If you ever make it public, audit for secrets first.

**What the `.gitignore` already excludes:**

- `dot-claude/cache/` — Claude's local statsig and telemetry cache
- `dot-claude/statsig/` — usage telemetry, machine-local
- `dot-claude/stats-cache.json` — session statistics
- `dot-claude/mcp-needs-auth-cache.json` — MCP auth state cache
- `dot-claude/shell-snapshots/` — ephemeral shell state
- `dot-claude/file-history/` — local file read history
- `dot-claude/debug/` — debug dumps
- `dot-claude/backups/` — local backup copies (git is the backup)

**What is intentionally NOT in the repo and must be added locally after bootstrap:**

- `~/.claude.json` — your Anthropic auth tokens and account state. `dotclaude.json` in this repo is a convenience copy of the non-sensitive fields. After cloning on a new machine, you must authenticate manually (`claude /logout` then log in) or copy your `~/.claude.json` from another trusted machine over a secure channel. Do not commit a `~/.claude.json` that contains live auth tokens.

If you find credentials in any file in this repo: rotate them immediately, then remove them from git history with `git filter-repo` or BFG before pushing again.

---

## Agentic Patterns

The `dot-claude/CLAUDE.md` in this repo is not a simple instruction file — it encodes a multi-agent orchestration system. Here is a summary of what it enforces:

### Model routing

| Model | Role |
|-------|------|
| **Opus** | Orchestration only — architecture, planning, cross-domain design decisions, reviewing sub-agent output. Never reads raw code. |
| **Sonnet** | Implementation, non-trivial edits, test writing, integration work. |
| **Haiku** | Research, file reads, summarization, web fetches, linting, info gathering. Reads and compresses output for Opus to reason over. |

The cardinal pattern: Haiku reads, Opus reasons. Burning Opus on file reads is treated as a bug. Sub-agents are never Opus.

### Parallelism-first

Concurrency is the default, not an optimization. Any two independent tasks fan out as parallel sub-agent calls in a single batch. Sequential spawning is only correct when one output feeds the next. Large sessions with 100+ total agents are normal.

### TDD pipeline

Tests are written before implementation (Sonnet writes tests, then Sonnet writes code against them). If tests fail, a dedicated bugfix agent spawns automatically. Only green-test results bubble up. No implementation ships without prior test coverage.

### Domain-scoped documentation

Every subsystem gets its own `CLAUDE.md` — as small and focused as possible, maintained by a dedicated Haiku agent. An always-on "tail agent" monitors domain MDs for scope drift and proposes splits when a domain grows too broad. The goal: smaller contexts, more parallel agents, lower token cost per agent.

### Memory system

Memory files at `dot-claude/projects/*/memory/` build a persistent developer profile — preferences, stack conventions, feedback corrections, project state. Agents consult the profile before making choices. The system is self-updating: agents write back to memory files during sessions.

---

## Windows Junctions vs. Symlinks

Windows has two kinds of filesystem links relevant here: symlinks and directory junctions.

**Symlinks** require Administrator privileges (or Developer Mode enabled) to create. They also require an absolute path and distinguish between file and directory targets.

**Directory junctions** (what this repo uses) require no admin privileges and no Developer Mode. They are created with `cmd /c mklink /J <link> <target>` and work transparently with every application — Claude Code, your editor, git, everything. From any app's perspective, `~/.claude` is just a regular directory.

This is why `bootstrap.ps1` and `swap-to-junction.ps1` use `mklink /J` rather than `New-Item -ItemType SymbolicLink`. You do not need elevated privileges to set this up.

One behavioral note: junctions always store an absolute path. If you move the repo, re-run `bootstrap.ps1` to recreate the junction pointing at the new location.

---

## Contributing

PRs welcome. Useful contributions include:

- Improvements to the PowerShell scripts (error handling, cross-version compatibility, WSL support)
- Additional orchestration patterns for `CLAUDE.md` (new model routing heuristics, agent topologies)
- Additional example memory file templates
- A `restore.ps1` script to remove the junction and restore a backup in one step
- Cross-platform equivalents (macOS/Linux shell scripts using `ln -s`)

Open an issue first for large changes to `dot-claude/CLAUDE.md` — orchestration rule changes affect every session on every machine that uses this config.
