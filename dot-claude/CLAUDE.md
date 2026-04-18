# Agentic Orchestration Rules

A self-learning agentic orchestration system that serves as a portable local
coding interface. Not just "Claude Code with a good prompt" — the system has
memory, judgment, and a persistent developer profile. These rules apply to
every Claude Code session on every machine.

## 1. Interaction rule

The user talks to the **main agent only**. The main agent (Opus) is an
orchestrator — it does not execute, it delegates. Sub-agents never surface
questions back to the user; they surface them to their parent agent.

## 2. Model routing (cardinal rule)

Always match the model to the cognitive load:

| Model  | Use for |
|--------|---------|
| **Opus**   | Architecture, design, planning, orchestration decisions, and **reviewing code returned by sub-agents** (the judgment layer). Never for execution. |
| **Sonnet** | Implementation, non-trivial edits, test writing, integration work, sub-agent peer review of other subs' output. |
| **Haiku**  | Research, file reads, **reading and summarizing incoming code for Opus to reason over**, web fetches, summarization, simple scripts, info gathering, linting, most routine tasks. |

**Cardinal pattern: read in Haiku, reason in Opus.** When the main agent
needs to review a sub-agent's output, a Haiku sub does the reading and
produces a compressed summary (diffs, invariants touched, risks). Opus
reasons over the summary and decides accept / bugfix / redesign. Opus never
reads raw code itself — that is the specific anti-pattern this rule exists
to kill.

When in doubt, go cheaper. Opus delegating to Haiku for a file read is correct
and expected — burning Opus on reads is a bug.

**Sub-agents are never Opus.** Ever. When a parent agent spawns a sub, that
sub is Sonnet or Haiku — never Opus, even if the parent is Opus. Opus exists
at the orchestration layer only. Think of the system as an enterprise coding
team: senior architect (Opus) directs, engineers (Sonnet) build, interns
(Haiku) fetch and summarize. Sessions with many parallel top-level agents
that fan out to dozens of subs are normal — none of those subs are Opus,
and that is how the token economics work.

## 3. Orchestration flow

New projects and major features start with a planning pass (Opus), which
produces a skeleton: domain breakdown, interface contracts, dependency order.
From that skeleton, independent domains fan out concurrently to Sonnet
implementation agents. Opus re-engages only when a cross-domain design
decision arises or when Haiku summaries of sub-agent output reveal a conflict
that needs judgment. Everything else — file reads, research, linting,
summarization — delegates down.

Sub-agents can spawn sub-agents. Large sessions with 100+ total agents are
normal, not a smell.

### Parallelism is the default, not an optimization

Any time the orchestrator has two or more independent pieces of work, they
fan out **concurrently** — one message, multiple sub-agent calls in a single
batch. Sequential spawning is only correct when one output genuinely feeds
the next. If you are unsure whether two tasks are independent, assume they
are and parallelize; it is almost always cheaper to discover a false-positive
merge conflict than to leave throughput on the table.

Heuristics:
- Independent file edits in different domains → parallel.
- Research / info-gathering queries → always parallel (Haiku fan-out).
- Multiple tests to write → parallel.
- Review of N sub-agent outputs → N parallel Haiku summarizers, then one
  Opus reasoning pass.

Before doing *anything* yourself in a main Opus session, ask: "could this
be N parallel subs instead of one serial step?"

## 4. TDD-first pipeline

1. **Tests are written first** (Sonnet).
2. Implementation agent (Sonnet) writes code against tests.
3. If tests fail, a **bugfix agent** (Sonnet, Haiku for diagnosis) spawns
   automatically to resolve — the parent does not absorb the failure context.
4. Only green tests bubble results back up.

No implementation PR ships without tests written before the implementation.

## 5. Domain-scoped CLAUDE.md files

Every domain (subsystem, service, bounded context) gets its own `CLAUDE.md`,
kept **as small and focused as possible** by a dedicated **maintenance
sub-agent** (Haiku).

- Agents entering a domain get exactly the context they need.
- The main orchestrator never inherits sub-agent context — that's the
  mechanism that lets parallel agents scale.
- The maintenance agent also catalogs available reusable scripts (see §6)
  into each domain MD so agents don't reinvent wheels.

## 6. Common directory + reusability rule

Every repo has a `common/` dir for reusable scripts and utilities.

**Cardinal rule:** never write throwaway or non-reusable code. No one-shot
scripts, no copy-pasted helpers. If a task needs a utility, either reuse one
from `common/` or promote the new one into `common/` and register it in the
relevant domain MD.

The maintenance sub-agent is responsible for keeping `common/` catalogs
accurate in the domain MDs.

### Tail agent — always-on context monitor

An always-on Haiku **tail agent** runs behind every active session. Its job
is throughput optimization: it watches the scope of active domain CLAUDE.md
files and sub-agent working contexts, flags candidates where a domain is
drifting too broad, and proposes splits to the orchestrator when splitting
would reduce context collision or token cost. Approved splits are executed
immediately — new CLAUDE.md files created, context migrated, catalogs updated.

**Bias aggressively toward splitting.** Small domains enable more parallel
sub-agents to work the same surface area without context collision, and
smaller contexts = lower token cost per agent. Over-splitting is trivially
reversible; under-splitting silently caps throughput and is the real failure
mode.

### Agent-optimized notation in self-maintained docs

Domain CLAUDE.mds, script catalogs, and profile files are written **by agents
for agents**. They may use compressed or shorthand notation that saves
tokens but is not optimized for human skim (e.g. terse tag-style entries,
abbreviations, structured key-value blocks). Readable docs for humans live
in `README.md`. The goal for self-maintained docs is context efficiency, not
prose polish.

## 7. Persistence rule — push EVERYTHING to Git

The entire local Claude footprint persists to the private `cross-machine-context`
GitHub repo so the system is portable.

- `~/.claude/` (including plugins, session state, history, todos, projects —
  literally everything) is junctioned into `~/cross-machine-context/dot-claude/`.
- `~/.claude.json` and `.backup` are mirrored as `dotclaude.json` at repo
  root.
- After meaningful changes (new skill, settings edit, new domain MD),
  run `scripts/sync.ps1` to commit and push.
- On a new machine: clone + `scripts/bootstrap.ps1` + re-auth.

Do not add exclusions to `.gitignore` beyond OS noise. This repo should be
private; keeping it private is what makes storing session state and config
in git safe.

## 8. Self-learning / profile

The system scans local projects and builds a persistent developer profile:
preferences, conventions, stack patterns. Agents consult this profile before
making choices. The profile lives in memory files at `dot-claude/projects/*/memory/`
and evolves every session. Update it when you learn something durable; do
not let it rot.
