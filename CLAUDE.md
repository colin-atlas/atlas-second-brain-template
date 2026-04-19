# CLAUDE.md

Operating manual for this second brain. Every Claude Code session mounts this file as its working context.

## About This Second Brain

This vault is the second brain for **{{EXEC_NAME}}**, {{EXEC_ROLE}} at {{EXEC_COMPANY}}.

Claude Code reads this file on every session start to understand the vault's conventions and the executive's preferences.

## Directory Structure

| Directory | Purpose |
|---|---|
| `context/` | Who the executive is, their goals, how they work. Ground any work here. |
| `knowledge/` | Synthesized knowledge pages (entities, concepts, comparisons). Wiki-style. |
| `projects/` | Active and archived projects. Each has its own folder with `state.md` and `plan.md`. |
| `areas/` | Ongoing responsibilities — living docs for domains the executive owns. |
| `meetings/` | Dated meeting notes and debriefs. |
| `reports/` | Periodic reports — SOD/EOD, weekly, monthly. |
| `inbox/` | Raw unprocessed captures waiting to be ingested. |

## Frontmatter Contract

Every markdown file in this vault must have frontmatter:

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

### Type-specific additional fields

- **Knowledge pages:** `subtype` (entity | concept | comparison), `sources`, `related`
- **Meeting pages:** `subtype`, `date`, `attendees`
- **Project `state.md`:** `status` (active | paused | completed)
- **Inbox items:** `ingested` (true | false), `ingested_date`

### `updated` field
Any agent that modifies a file's content must update the `updated` field to the current date.

## Conventions

- Use Obsidian `[[wikilinks]]` for internal references, never markdown links.
- Lowercase kebab-case for filenames and tags (e.g., `ai-agents`, not `AI Agents`).
- Every file has at least one tag. No nested tags (e.g., `ai-agents`, not `ai/agents`).
- Check `knowledge/_index.md` first when answering knowledge questions.

## Skills

- **`/ingest <path>`** — Process an inbox item, meeting note, or article into synthesized knowledge pages.
- **`/lint`** — Audit and auto-fix vault health (frontmatter, wikilinks, indexes).

## Working Style

{{Fill in from intake — e.g., preferred communication style, decision-making style, how the exec wants updates, tone/voice}}

## Preferences

{{Fill in from intake — e.g., direct vs. elaborate, bullet points vs. prose, batch vs. real-time}}
