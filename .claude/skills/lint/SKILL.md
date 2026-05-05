---
name: lint
description: Audit and auto-fix vault health — missing frontmatter, orphan pages, broken wikilinks, typed-link reciprocity, stale content, missing cross-references, and index sync issues. Runs across the entire vault.
tools: Read, Write, Edit, Glob, Grep, Bash
---

# Vault Lint

Audit the entire vault for structural, graph, content, and index health issues. Auto-fix what can be fixed safely. Flag everything else for review.

## Trigger

Manual invocation: `/lint` (advisory) or `/lint --fix` (auto-fix structural issues; also enabled when invoked by `dream-cycle`).

## Workflow

### Phase 1: Scan All Files

```bash
find . -name "*.md" -not -path "./.obsidian/*" -not -path "./.claude/*" | sort
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
- Knowledge pages: `subtype` (person/company/tool/concept/comparison), `sources`, `related`
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

### Phase 7: Content Graph Health

This phase runs only on files inside `{{VAULT_NAME}}/writing-system/content-graph/`. Load the contracts from `writing-system/content-graph/README.md` to know what to check.

**Per-node-type frontmatter validation.** For each file inside `content-graph/{takes,stories,ideas,topics,receipts,quotes}/`, verify the type-specific frontmatter beyond the universal vault contract:

| Node type | Required type-specific fields |
|---|---|
| **takes** | `subtype: content-take`, `date`, `source`, `topics`, `related_takes`, `related_stories`, `private` |
| **stories** | `subtype: content-story`, `date`, `source`, `narrator`, `characters`, `topics`, `related_takes`, `related_stories`, `related_receipts`, `evergreen`, `usable_for`, `used_in`, `private` |
| **ideas** | `subtype: content-idea`, `date_found`, `source`, `source_url`, `angles`, `topics`, `related_topics`, `private` |
| **topics** | `subtype: content-topic`, `linked_knowledge`, `related_topics` |
| **receipts** | `subtype: content-receipt`, `metric`, `value`, `timeframe`, `source_story`, `topics`, `usable_for`, `private` |
| **quotes** | `subtype: content-quote`, `author`, `author_handle`, `source_url`, `source_title`, `source_link`, `topics`, `private` |

**Auto-fix:** Add missing required fields with empty defaults (`[]`, `""`, `false` as appropriate). Never infer values that require judgment (e.g., `usable_for`, `evergreen`, `narrator`) — leave those empty for manual review.

**Flag only:** entries whose frontmatter doesn't match any node-type contract (probably the file is in the wrong directory).

**Per-node-type staleness thresholds:**

| Node type | Stale threshold |
|---|---|
| takes | `updated` more than 90 days old |
| stories | `updated` more than 90 days old |
| ideas | `updated` more than 60 days old (faster-trending) |
| topics, receipts, quotes | No auto-stale check (evergreen by nature) |

**Flag only:** stale entries listed by node type. Never auto-archive — manual review only.

**Topic gap detection.** For each tag in the 16-tag taxonomy (see `content-graph/README.md`):
- Count entries across `takes/`, `stories/`, `ideas/` that carry this tag.
- If 5+ entries exist for the tag AND no `topics/{tag}.md` page exists → flag as a topic page worth creating.

**Underused topic page detection.** For each `topics/*.md`:
- Count incoming wikilinks from `takes/`, `stories/`, `ideas/`, `receipts/`, `quotes/`.
- If fewer than 3 → flag as underused (likely created prematurely).

**Untagged entries.** For entries with `tags: - untagged`:
- If `updated` is more than 14 days old → flag for manual tagging review. (Recently-untagged entries are still in the normal review window from `content-ingest` runs.)

**Cross-graph wikilink validation.** For each `topics/*.md`:
- Check the `linked_knowledge:` frontmatter field.
- If non-empty, verify the wikilink target file exists at the path inside `{{VAULT_NAME}}/knowledge/`.
- Flag broken cross-graph wikilinks for repair.

### Phase 8: Typed-Link Reciprocity

For every page with typed `related:` entries, verify each typed link has its reciprocal on the target page.

**Reciprocal pairs (from CLAUDE.md taxonomy):**

| Forward | Reciprocal |
|---|---|
| `attended` (meeting → person) | `attended_by` (person → meeting) |
| `works_at` (person → company) | `employs` (company → person) |
| `founder_of` (person → company) | `founded_by` (company → person) |
| `built_by` (tool → company) | `builds` (company → tool) |
| `mentions` (any → entity) | `mentioned_in` (entity → any) |
| `implements` / `applies` (any → concept) | `applied_in` (concept → any) |
| `competitor_to` (tool ↔ tool) | `competitor_to` (symmetric — same on both sides) |
| `derived_from` (concept → concept) | `parent_of` (concept → concept) |
| `supersedes` (concept → concept) | `superseded_by` (concept → concept) |
| `references` (any → any) | `references` (symmetric) |

**Algorithm:**

1. Walk all pages with typed `related:` entries.
2. For each typed link `(source, type, target)`, check the target's `related:` for the reciprocal type pointing back to source.
3. If missing:
   - **Default mode:** flag in the lint report — "Page A has `founder_of` linking to B, but B has no `founded_by` linking back."
   - **`--fix` mode (also enabled when invoked by dream-cycle):** append the reciprocal entry to the target's `related:` frontmatter.

**Validation:**

- Reject any `type:` value not in the taxonomy. Flag for manual review (likely a typo or a new type that should be added to CLAUDE.md first).
- Reject malformed entries (missing `link:` or `type:` key). Auto-fix is unsafe here — flag only.

**Output:** Add a `## Phase 8 — Typed-Link Reciprocity` section to the lint report with one line per fixable issue and a separate list of unfixable / manual-review issues.

### Phase 9: Report

*(was Phase 8 before typed-link reciprocity was added in Task 5 / phase1.)*

Output the full lint report in this format:

```
Vault Lint Report — <date>

Auto-fixed:
  <N> files — added missing frontmatter
  <N> files — added missing required fields
  <N> files — added cross-reference wikilinks
  <N> files — added to knowledge/_index.md
  <N> files — added to project-index.md
  <N> content-graph entries — added missing type-specific frontmatter fields

Flagged for review:
  <file> — <issue description>
  <file> — <issue description>

Tag audit:
  Single-use tags: <tag1>, <tag2>
  Possible duplicates: <tag-a> / <tag-b>

Content graph:
  Stale takes (>90d): <N> — <files>
  Stale stories (>90d): <N> — <files>
  Stale ideas (>60d): <N> — <files>
  Topic page candidates (5+ entries, no topic page): <tag1> (<N> entries), <tag2> (<N> entries)
  Underused topic pages (<3 wikilinks): <topic1>, <topic2>
  Untagged entries needing review (>14d old): <N> — <files>
  Broken cross-graph wikilinks: <file> — points at missing <knowledge/path>

Typed-link reciprocity:
  <N> fixed (reciprocal entries appended to target frontmatter)
  <M> flagged for review (invalid type, malformed entry, or missing target page)

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
