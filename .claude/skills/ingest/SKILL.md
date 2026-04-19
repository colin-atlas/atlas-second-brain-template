---
name: ingest
description: Process raw captures (inbox items, meeting notes, articles) into synthesized knowledge pages. Creates or updates entity, concept, and comparison pages in knowledge/ with full frontmatter, cross-references, and wikilinks.
tools: Read, Write, Edit, Glob, Grep, Bash
---

# Ingest

Process a source document into the knowledge base. Creates or updates wiki-style knowledge pages, adds cross-references, and maintains the knowledge index.

## Trigger

- **Manual (mode A):** User runs `/ingest <path>` or says "ingest this"
- **Agent-driven (mode B):** Agent invokes after capturing raw material. If the source isn't filed yet, write it to `inbox/` with frontmatter first, then ingest from that path.

## Input

A file path to a source document (inbox item, meeting note, article, or any markdown file in the vault).

## Workflow

### Phase 1: Analyze the Source

1. Read the source file completely
2. Extract:
   - **Entities** — specific tools, products, people, companies mentioned
   - **Concepts** — ideas, patterns, methodologies, frameworks discussed
   - **Facts** — concrete details, data points, decisions, outcomes
   - **Connections** — how this source relates to existing knowledge, projects, or areas

### Phase 2: Identify Knowledge Targets

For each entity and concept extracted, determine:
- Does a page already exist? Search `knowledge/entities/`, `knowledge/concepts/`, and `knowledge/comparisons/`
- Should a new page be created?
- Should an existing page be updated?
- If 2+ entities in the same domain are now covered, should a comparison page be created?

**Decision rules:**
- Create a page when the source provides enough substance for a meaningful entry (not just a passing mention)
- Update a page when new information adds to or refines what's already there
- Create a comparison page when 3+ entities in the same domain have been ingested
- Prefer updating over creating — check for existing pages first

### Phase 3: Create or Update Knowledge Pages

For each target, create or update the page following these templates:

**Entity page** (`knowledge/entities/<name>.md`):

```yaml
---
title: <Entity Name>
type: knowledge
subtype: entity
tags:
  - <domain-tag>
  - <specific-tag>
sources:
  - "[[<path-to-source>]]"
related:
  - "[[knowledge/concepts/<related-concept>]]"
created: <today>
updated: <today>
---
```

```
# <Entity Name>

<2-3 sentence summary of what this entity is>

## Key Details

<Structured information — what it does, how it works, key features, pricing if relevant>

## Relevance to Atlas

<Why this matters to Colin/Atlas — connection to current projects, strategy, or operations>

## Related

- [[knowledge/concepts/<concept>]] — <one-line description of relationship>
- [[knowledge/entities/<entity>]] — <one-line description of relationship>
```

**Concept page** (`knowledge/concepts/<name>.md`):

```yaml
---
title: <Concept Name>
type: knowledge
subtype: concept
tags:
  - <domain-tag>
sources:
  - "[[<path-to-source>]]"
related:
  - "[[knowledge/entities/<related-entity>]]"
created: <today>
updated: <today>
---
```

```
# <Concept Name>

<2-3 sentence summary of this concept>

## How It Works

<Core mechanics, principles, or framework>

## Application to Atlas

<How this concept applies to Colin's work, Atlas's strategy, or agent operations>

## Related

- [[knowledge/entities/<entity>]] — <one-line description>
```

**Comparison page** (`knowledge/comparisons/<name>.md`):

```yaml
---
title: <Comparison Title>
type: knowledge
subtype: comparison
tags:
  - <domain-tag>
sources:
  - "[[<path-to-source-1>]]"
  - "[[<path-to-source-2>]]"
related:
  - "[[knowledge/entities/<entity-1>]]"
  - "[[knowledge/entities/<entity-2>]]"
created: <today>
updated: <today>
---
```

```
# <Comparison Title>

<1-2 sentence summary of what's being compared and why>

## Comparison

| Feature | <Entity 1> | <Entity 2> | <Entity 3> |
|---------|------------|------------|------------|
| <feature> | <detail> | <detail> | <detail> |

## Recommendation

<Which option fits Atlas's needs and why>

## Related

- [[knowledge/entities/<entity-1>]] — <detail>
- [[knowledge/entities/<entity-2>]] — <detail>
```

**When updating an existing page:**
- Add new information under the appropriate section
- Add the new source to the `sources` frontmatter list
- Add any new related pages to the `related` frontmatter list
- Update the `updated` date
- Do NOT remove or overwrite existing content — merge additively

### Phase 4: Add Cross-References

- Add wikilinks between new/updated knowledge pages
- Add wikilinks from knowledge pages to relevant project, area, or context pages where the connection is meaningful
- Ensure every knowledge page has a `## Related` section at the bottom with wikilinks and one-line descriptions

### Phase 5: Update the Knowledge Index

Add new entries to `knowledge/_index.md` under the appropriate category (Concepts, Entities, Comparisons). Format:

```
- [[<subtype>/<filename>]] — <one-line description>
```

If a category section still has the placeholder text ("_No concept pages yet..."), replace it with the first entry.

### Phase 6: Tag the Source

Update the source file's frontmatter:
- Set `ingested: true`
- Set `ingested_date: <today>`
- If the source has no frontmatter, add it with `type: inbox` and appropriate tags
- Do NOT modify the source's content — only frontmatter

### Phase 7: Report

Output a summary of all actions taken:

```
Ingest complete — <source filename>

Created:
  knowledge/entities/<name>.md
  knowledge/concepts/<name>.md

Updated:
  knowledge/entities/<existing>.md (added <what>)

Cross-references added:
  <page-1> ←→ <page-2>

Index updated:
  knowledge/_index.md (added N entries)

Source tagged:
  <source-path> → ingested: true
```

## Rules

- Source material is immutable — never modify or delete source content (only frontmatter)
- One ingest pass can create/update multiple knowledge pages
- Always check for existing pages before creating — prefer updating over duplicating
- Follow the frontmatter convention exactly (see CLAUDE.md)
- Every knowledge page must have at least one `sources` entry and one `related` entry
- Use kebab-case for all filenames
- Use wikilinks (`[[path]]`) for all internal references, not markdown links
