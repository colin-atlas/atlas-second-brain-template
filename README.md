# Atlas Second Brain Template

A starter template for an executive's AI-powered second brain — an Obsidian vault wired into Claude Code. Delivered as part of the Atlas AI Workspace Setup.

Learn more about Atlas: https://atlasassistants.com

## What's Inside

- `CLAUDE.md` — operating manual Claude Code reads on every session. Fill in the executive's details.
- `context/user.md` — template for the executive's identity, goals, working style, and preferences.
- `knowledge/_index.md` — scaffold for the knowledge graph. Populated by the `ingest` skill.
- `projects/project-index.md` — scaffold for active and archived projects.
- `areas/`, `meetings/`, `reports/`, `inbox/` — empty scaffolded directories.
- `.claude/skills/ingest/` — skill that turns raw captures into synthesized knowledge pages.
- `.claude/skills/lint/` — skill that audits and auto-fixes vault health.

## Getting Started

1. Clone this repo into the location of your choice (default: `~/brain/`):

   ```bash
   git clone <repo-url> ~/brain
   cd ~/brain
   ```

2. Open the folder as a vault in [Obsidian](https://obsidian.md).

3. Fill in the placeholders in `CLAUDE.md` and `context/user.md`. Search for `{{` to find them.

4. Install [Claude Code](https://docs.anthropic.com/claude/claude-code) and launch from the vault root:

   ```bash
   cd ~/brain
   claude
   ```

5. (Optional) Enable [Obsidian Sync](https://obsidian.md/sync) for real-time multi-device access.

6. (Recommended) Install the [Obsidian Git](https://github.com/Vinzent03/obsidian-git) plugin and configure auto-commit + push every 5 minutes to a private Git repo you own. This enables Claude Code scheduled/cloud automations and acts as version history.

## Full Workspace Setup

This template is one piece of the Atlas AI Workspace Setup, which also covers IDE setup, Claude Code plugins, and Composio integrations. Atlas clients get the full setup delivered by their matched EA or the Atlas core team.

## Skills Included

### `ingest`
Processes raw captures (inbox items, meeting notes, articles) into synthesized knowledge pages. Creates or updates entity, concept, and comparison pages with full frontmatter, cross-references, and wikilinks.

Invoke: `/ingest <path>` or "ingest this".

### `lint`
Audits and auto-fixes vault health — missing frontmatter, orphan pages, broken wikilinks, stale content, and index sync issues. Runs across the entire vault.

Invoke: `/lint` or "lint the vault".
