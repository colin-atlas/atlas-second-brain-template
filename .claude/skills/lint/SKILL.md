---
name: lint
description: Audit and auto-fix vault health — missing frontmatter, orphan pages, broken wikilinks, stale content, missing cross-references, and index sync issues. Runs across the entire vault.
tools: Read, Write, Edit, Glob, Grep, Bash
---

# Vault Lint

Audit the entire vault for structural, graph, content, and index health issues. Auto-fix what can be fixed safely. Flag everything else for review.

## Trigger

Manual invocation: `/lint` or "lint the vault"

## Workflow

### Phase 1: Scan All Files

```bash
find . -name "*.md" -not -path "./.obsidian/*" -not -path "./.claude/skills/*" | sort
```

For each file, read its frontmatter (if any) and note its directory.

### Phase 2: Structural Health

Check every markdown file for the required frontmatter fields.

**Required fields (all files):**
- `title` — infer from first `# heading` or filename if missing
- `type` — infer from directory: `context/` → context, `knowledge/` → knowledge, `projects/` → project, `areas/` → area, `meetings/` → meeting, `reports/` → report, `inbox/` → inbox, `sessions/` → session
- `tags` — infer from content keywords, directory, and filename if missing. Every file must have at least one tag.
- `created` — use file system creation date if missing
- `updated` — use file system modification date if missing

**Additional fields by type:**
- Knowledge pages: `subtype` (entity/concept/comparison), `sources`, `related`
- Meeting pages: `date`, `attendees`
- Project state.md: `status` (active/paused/completed)
- Inbox items: `ingested` (true/false), `ingested_date`

**Auto-fix:** Add missing frontmatter and fields. Preserve all existing fields — never overwrite.

**Flag only:** `type` field doesn't match the directory the file lives in (might be intentional).

### Phase 3: Graph Health

Scan all wikilinks in all files. Build two maps:
1. **Outbound links:** for each file, what does it link to?
2. **Inbound links:** for each file, what links to it?

**Checks:**

| Issue | Action |
|-------|--------|
| Orphan pages (0 inbound wikilinks, excluding index files) | Add wikilink from the relevant index or overview page |
| Broken wikilinks (target file doesn't exist) | Flag with suggested correction (closest filename match) |
| Knowledge pages that discuss the same tags/topics but don't link to each other | Add wikilinks in `## Related` section |
| Knowledge pages with no `related` frontmatter | Populate from wikilinks found in the page content |
| Knowledge pages not listed in `knowledge/_index.md` | Add entry to the index |

### Phase 4: Content Health

| Issue | Action |
|-------|--------|
| Active project `state.md` with `status: active` and `updated` > 90 days old | Flag as potentially stale |
| Inbox items > 14 days old without `ingested: true` | Flag as untriaged |
| Two knowledge pages with very similar titles or overlapping `sources` | Flag as possible duplicate for manual merge |
| Pages with < 3 lines of non-frontmatter content | Flag as incomplete/stub |

### Phase 5: Index Health

| Check | Action |
|-------|--------|
| Knowledge pages not in `knowledge/_index.md` | Add them under the correct category |
| Project directories not in `projects/project-index.md` | Add them with status |
| Root `index.md` missing links to new top-level sections | Add them |
| `knowledge/_index.md` entries pointing to files that don't exist | Remove the entry |

### Phase 6: Tagging Consistency

- Scan all tags across the vault
- Flag tags that appear only once (possible typo or inconsistency)
- Flag tags that look like duplicates (e.g., `ai-agent` vs `ai-agents`)
- Do not auto-fix tag issues — flag for review

### Phase 7: Report

Output the full lint report in this format:

```
Vault Lint Report — <date>

Auto-fixed:
  <N> files — added missing frontmatter
  <N> files — added missing required fields
  <N> files — added cross-reference wikilinks
  <N> files — added to knowledge/_index.md
  <N> files — added to project-index.md

Flagged for review:
  <file> — <issue description>
  <file> — <issue description>

Tag audit:
  Single-use tags: <tag1>, <tag2>
  Possible duplicates: <tag-a> / <tag-b>

No action needed:
  <N> files passed all checks
```

## Rules

- **Never delete files** — only add content (frontmatter, wikilinks, index entries)
- **Never merge duplicates** — flag them for manual review
- **Never rewrite content** — only add frontmatter, `## Related` sections, and index entries
- **Preserve existing frontmatter** — when adding missing fields, keep everything that's already there
- **Load-bearing directories** (`meetings/`, `reports/`, `sessions/`) — only add missing frontmatter, never restructure or rename files
- **Skip non-content files** — ignore `.gitkeep`, images, and files in `.obsidian/`
