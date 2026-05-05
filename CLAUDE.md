# CLAUDE.md

*Replace `{{...}}` placeholders during onboarding. Run `/onboard` after filling them in. See `SETUP.md` for the full setup runbook.*

This file is the operating manual for all agents working in this vault. Every agent that mounts this vault — Claude Code or any future agent — follows these conventions.

## What This Is

{{EXEC_NAME}}'s second brain — an Obsidian vault that serves as the shared knowledge layer for {{EXEC_NAME}}, {{EXEC_ROLE}} at {{EXEC_COMPANY}}. Synced via Obsidian Sync across devices and agent workspaces. Agents are the primary writers.

## Directory Architecture

| Directory | Purpose | What goes here | What does NOT go here |
|-----------|---------|---------------|----------------------|
| `context/` | Core identity (layer 1 of the brain) | Who the executive is, what the company is, strategic direction | Synthesized research, project specifics |
| `knowledge/` | Synthesized wiki (layer 2 of the brain) — *world facts* | People, company, tool, concept, and comparison pages — what you know | Raw captures, opinions, action items |
| `projects/` | Active work | Initiatives with `state.md` + `plan.md`. Catalog: `project-index.md`. Archive: `projects/archive/` | General knowledge that outlives the project |
| `areas/` | Responsibilities | Living docs about ongoing domains | Research about topics (use `knowledge/`) |
| `meetings/` | Meeting debriefs | Dated debriefs. **Load-bearing — do not restructure.** | Action items (those go to projects) |
| `reports/` | Periodic reports | SOD/EOD, weekly, monthly. **Load-bearing — do not restructure.** | — |
| `sessions/` | Agent logs | One file per agent per day. **Load-bearing — do not restructure.** | — |
| `inbox/` | Raw capture | Unprocessed items waiting for ingest | Anything already ingested or triaged |
| `.claude/` | Tooling | Project-level skills and plugin bundles used when working in this vault | — |

### Knowledge subdirectories

- `knowledge/people/` — one page per human (teammate, client, public figure, founder)
- `knowledge/companies/` — one page per organization
- `knowledge/tools/` — software, products, services
- `knowledge/concepts/` — ideas, patterns, methodologies, frameworks
- `knowledge/comparisons/` — synthesis across multiple entities or concepts
- `knowledge/_index.md` — Catalog of all knowledge pages. **Read this first when answering knowledge queries.**

### Areas

These are starting-point areas — rename, add, or remove to match the executive's actual responsibilities.

- `areas/content/` — Content strategy and production
- `areas/finances/` — Financial planning and tracking
- `areas/operations/` — Automations registry, infrastructure tracking, ops health (`automations.md` is the source of truth for every scheduled / event-triggered automation)
- `areas/product/` — Product development and roadmap
- `areas/strategic-planning/` — Business strategy and direction

## Frontmatter Contract

Every markdown file in this vault must have this frontmatter:

```yaml
---
title: Page Title
type: context | knowledge | project | area | meeting | report | inbox | session
tags:
  - at-least-one-tag
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### Additional fields by type

**Knowledge pages** also require:
- `subtype`: `person | company | tool | concept | comparison`
- `sources`: list of wikilinks to source material
- `related`: list of wikilinks to related knowledge pages

**Meeting pages** also require:
- `subtype`: `standup`, `1on1`, `l10`, `sync`, `training`, `coaching`, `external`, or `meeting` (generic fallback)
- `date`: YYYY-MM-DD
- `attendees`: list of names

**Project state.md** also requires:
- `status`: active | paused | completed

**Inbox items** also require:
- `ingested`: true | false
- `ingested_date`: YYYY-MM-DD | null

### `updated` field contract

Any agent that modifies a file's content (not just reads it) must update the `updated` field to the current date.

## Tagging Rules

- Lowercase, kebab-case: `ai-memory`, `managed-service`, `content-strategy`
- **Domain tags** for cross-cutting topics: `ai-agents`, `product`, `operations`, `strategy`, `content`, `finances`
- **Entity tags** for specific things: names of teammates, tools, projects
- Flat tags only — no nesting (not `ai/agents`)
- Every page gets at least one tag

## Naming Conventions

- All files and folders: lowercase kebab-case
- Meeting notes: prefixed with date (`YYYY-MM-DD-topic.md`)
- Session logs: `YYYY-MM-DD-agent-name.md` (one file per agent per day)
- Reports: `YYYY-MM-DD-report-type.md` (e.g., `2026-04-05-sod.md`, `2026-04-05-weekly.md`)
- Knowledge pages: named after the entity or concept (e.g., `notion.md`, `ai-memory-systems.md`)
- Catalog files: `_index.md` (underscore prefix sorts to top)

## Wikilink Rules

- Always use Obsidian `[[wikilink]]` syntax for internal references, never standard markdown links.
- Every knowledge page must have a `## Related` section at the bottom with wikilinks and one-line descriptions.
- When creating or updating a page, add wikilinks to related pages in both directions (if A links to B, B should link to A).

### Typed `related:` frontmatter

Knowledge pages, project pages, and meeting/report pages express relationships as **typed entries** in `related:` frontmatter:

```yaml
related:
  - link: "[[knowledge/people/jane-doe]]"
    type: founder_of
  - link: "[[knowledge/companies/example-co]]"
    type: implements
  - link: "[[knowledge/concepts/some-framework]]"
    type: applies
```

**Starter type taxonomy (10 concepts, ~17 strings — directionality matters; reciprocals enforced by lint Phase 8):**

| Type | Used between | Reciprocal | Example |
|---|---|---|---|
| `attended` | meeting → person | `attended_by` | meeting page links Jane as attendee |
| `works_at` | person → company | `employs` | Jane `works_at` Example Co |
| `founded_by` / `founder_of` | company ↔ person | (each other) | Example Co `founded_by` Jane; Jane `founder_of` Example Co |
| `built_by` / `builds` | tool ↔ company | (each other) | ToolX `built_by` Anthropic; Anthropic `builds` Claude Code |
| `mentions` | any → entity | `mentioned_in` | a note mentions a tool with no stronger relation |
| `implements` / `applies` | any → concept | `applied_in` | a project `applies` a methodology |
| `competitor_to` | tool ↔ tool | `competitor_to` (symmetric) | ToolA `competitor_to` ToolB |
| `derived_from` | concept → concept | `parent_of` | new-pattern `derived_from` base-pattern |
| `supersedes` | concept → concept | `superseded_by` | the new pattern `supersedes` the old one |
| `references` | any → any | `references` (symmetric) | catch-all when no stronger type fits |

`lint` enforces reciprocity by type — if `A founder_of B`, then `B founded_by A` must exist.

### Filing-rules mandate

Every brain-writing skill (`knowledge-ingest`, `meeting-ingest`, `report-ingest`) MUST start with:

> Before creating any new page, read `RESOLVER.md` and file by primary subject, not by source format.

## Skills

The template ships with seven skills, all auto-discovered from `.claude/skills/`:

- **Onboard** (`/onboard`) — One-time cold-start orchestration. Walks through filling placeholders, scaffolding the vault, and bootstrapping initial knowledge pages from intake material.
- **Meeting ingest** (`/meeting-ingest <path>`) — Process a meeting note into people timelines, entity timelines, and project action candidates.
- **Report ingest** (`/report-ingest <path>`) — Process a daily/weekly/monthly report into project + area updates.
- **Knowledge ingest** (`/knowledge-ingest <path>`) — Process raw captures (inbox items, articles, pasted text) into synthesized knowledge graph pages (people, companies, tools, concepts, comparisons).
- **Dream cycle** (`/dream-cycle`) — Nightly maintenance pass. Auto-ingests today's captures, runs `lint --fix`, flags orphans/stale content, synthesizes session logs into candidate inbox items. Outputs to `reports/dream-cycle/YYYY-MM-DD.md`.
- **Triage** (`/triage`) — Periodic action-candidate cleanup using a 7-class / 3-lane sort to keep the project action queue clean.
- **Lint** (`/lint`) — Audit and auto-fix vault health (frontmatter, orphans, broken wikilinks, typed-link reciprocity, stale content).

## Working With This Vault

- **Answering knowledge questions:** Check `knowledge/_index.md` first, then relevant knowledge pages. If the answer isn't in knowledge, check `context/`, `projects/`, and `meetings/`.
- **Processing new material:** Use `/knowledge-ingest` for material that becomes wiki-style knowledge pages (entities, concepts, comparisons). Don't just drop things in inbox and leave them.
- **Creating files:** Follow naming conventions, add full frontmatter, add wikilinks from the relevant index.
- **Before creating a knowledge page:** Search `knowledge/_index.md` and existing pages first. Update an existing page rather than creating a duplicate.
- **Do not reorganize load-bearing directories** (`meetings/`, `reports/`, `sessions/`) — other agents depend on their current structure and format.

## Session Start Routine

At the start of every session, silently load minimal orientation context:

1. **Core identity** — Read `context/user.md` and `context/company.md`
2. **Active projects** — Read `projects/project-index.md`
3. **Last session** — Read the most recent files in `sessions/` for continuity

Note: in a freshly scaffolded template, `context/` and the index files may be sparse. They fill in as the executive's intake material is processed and as agents begin recording sessions.

The vault is wiki-linked — follow links as needed based on the user's actual task.

## Context Management

### Before compaction

When a session is getting long and compaction is approaching:
1. **Update project state** — If working on a project, write current status and progress to its `state.md`
2. **Update implementation plans** — If there's an active `plan.md`, update it with what's done and what's next
3. **Write a session log** — Append to or create `sessions/YYYY-MM-DD-agent-name.md` with tasks completed, decisions made, and open threads

This ensures recovery is reading files, not reconstructing from memory.

### After compaction

1. Re-read the project `state.md` and `plan.md` you were working on
2. Re-read the session log you just wrote
3. Re-read any files you were actively editing
4. Do **not** re-read files you already summarized in response text — that survives compaction

### General discipline

- Avoid reading entire large files when you only need a section — use `offset` and `limit`
- Don't load `meetings/`, `reports/`, or `projects/archive/` unless explicitly relevant
- Summarize key facts in response text so they survive compaction
- Trust the wikilink graph to find what you need on demand

## Session Logging

Agents should log their work to `sessions/` for cross-session continuity.

- **When to write:** At the end of a substantive session, or before compaction during a long session
- **Filename:** `YYYY-MM-DD-agent-name.md` (e.g., `2026-04-05-claude-code.md`)
- **If a log already exists for today:** Append to it rather than creating a new file
- **What to include:** Tasks completed, decisions made, files changed, open threads for next session
- **What to skip:** Routine reads, failed attempts, trivial changes
- **Frontmatter:** Use `type: session` with appropriate tags

## User Preferences

- Communication: {{COMMUNICATION_STYLE}}
- Decisions: {{DECISION_STYLE}}
- Updates: {{UPDATE_CADENCE}}
- Voice / tone: {{VOICE_TONE}}
