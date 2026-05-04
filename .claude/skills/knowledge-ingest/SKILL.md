---
name: knowledge-ingest
description: Process raw captures (inbox items, meeting notes, articles) into synthesized knowledge graph pages. Creates or updates person, company, tool, concept, and comparison pages in `{{VAULT_NAME}}/knowledge/` with full frontmatter, cross-references, and wikilinks. For ingestion into the content graph ({{VAULT_OWNER_SHORT_NAME}}'s takes, stories, voice material), use `/content-ingest` instead.
tools: Read, Write, Edit, Glob, Grep, Bash
---

> **Filing-rules mandate (from `RESOLVER.md`):** Before creating any new page, read `RESOLVER.md` (at the vault root) and file by primary subject, not by source format. Subject routing: person → `knowledge/people/`, company → `knowledge/companies/`, tool → `knowledge/tools/`, concept → `knowledge/concepts/`, comparison → `knowledge/comparisons/`.

# Knowledge Ingest

Process a source document into the knowledge graph at `{{VAULT_NAME}}/knowledge/`. Creates or updates wiki-style person / company / tool / concept / comparison pages, adds cross-references, and maintains the knowledge index.

For {{VAULT_OWNER_SHORT_NAME}}'s voice material (takes, stories, perspectives from transcripts and voice memos), use `/content-ingest` — that skill writes to `writing-system/content-graph/` instead.

## Trigger

- **Manual (mode A):** User runs `/knowledge-ingest <path>` or says "knowledge-ingest this"
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
- Does a page already exist? Search `knowledge/people/`, `knowledge/companies/`, `knowledge/tools/`, `knowledge/concepts/`, and `knowledge/comparisons/`
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

**Person page** (`knowledge/people/<kebab-name>.md`):

```yaml
---
title: <Person Name>
type: knowledge
subtype: person
tags:
  - <domain-tag>
sources:
  - "[[<path-to-source>]]"
related:
  - link: "[[knowledge/companies/<company>]]"
    type: works_at
  - link: "[[knowledge/concepts/<concept>]]"
    type: applies
created: <today>
updated: <today>
---
```

```
# <Person Name>

<2-3 sentence summary of who this person is>

## Key Details

<Structured information — role, background, notable work, relationship to {{VAULT_OWNER_ORG_NAME}}>

## Relevance to {{VAULT_OWNER_ORG_NAME}}

<Why this person matters to {{VAULT_OWNER_SHORT_NAME}}/{{VAULT_OWNER_ORG_NAME}} — connection to current projects, strategy, or operations>

## Related

- [[knowledge/companies/<company>]] — <one-line description of relationship>
- [[knowledge/concepts/<concept>]] — <one-line description of relationship>
```

**Company page** (`knowledge/companies/<kebab-name>.md`):

```yaml
---
title: <Company Name>
type: knowledge
subtype: company
tags:
  - <domain-tag>
sources:
  - "[[<path-to-source>]]"
related:
  - link: "[[knowledge/people/<founder>]]"
    type: founded_by
created: <today>
updated: <today>
---
```

```
# <Company Name>

<2-3 sentence summary of what this company is>

## Key Details

<Structured information — what it does, how it works, key offerings, pricing if relevant>

## Relevance to {{VAULT_OWNER_ORG_NAME}}

<Why this matters to {{VAULT_OWNER_SHORT_NAME}}/{{VAULT_OWNER_ORG_NAME}} — connection to current projects, strategy, or operations>

## Related

- [[knowledge/people/<founder>]] — <one-line description of relationship>
- [[knowledge/tools/<product>]] — <one-line description of relationship>
```

**Tool page** (`knowledge/tools/<kebab-name>.md`):

```yaml
---
title: <Tool Name>
type: knowledge
subtype: tool
tags:
  - <domain-tag>
sources:
  - "[[<path-to-source>]]"
related:
  - link: "[[knowledge/companies/<maker>]]"
    type: built_by
  - link: "[[knowledge/concepts/<related-concept>]]"
    type: implements
created: <today>
updated: <today>
---
```

```
# <Tool Name>

<2-3 sentence summary of what this tool is>

## Key Details

<Structured information — what it does, how it works, key features, pricing if relevant>

## Relevance to {{VAULT_OWNER_ORG_NAME}}

<Why this matters to {{VAULT_OWNER_SHORT_NAME}}/{{VAULT_OWNER_ORG_NAME}} — connection to current projects, strategy, or operations>

## Related

- [[knowledge/companies/<maker>]] — <one-line description of relationship>
- [[knowledge/concepts/<concept>]] — <one-line description of relationship>
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
  - link: "[[knowledge/people/<author>]]"
    type: references
  - link: "[[knowledge/tools/<example>]]"
    type: applied_in
created: <today>
updated: <today>
---
```

```
# <Concept Name>

<2-3 sentence summary of this concept>

## How It Works

<Core mechanics, principles, or framework>

## Application to {{VAULT_OWNER_ORG_NAME}}

<How this concept applies to {{VAULT_OWNER_SHORT_NAME}}'s work, {{VAULT_OWNER_ORG_NAME}}'s strategy, or agent operations>

## Related

- [[knowledge/tools/<tool>]] — <one-line description>
- [[knowledge/people/<person>]] — <one-line description>
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
  - link: "[[knowledge/tools/<entity-1>]]"
    type: references
  - link: "[[knowledge/tools/<entity-2>]]"
    type: references
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

<Which option fits {{VAULT_OWNER_ORG_NAME}}'s needs and why>

## Related

- [[knowledge/tools/<entity-1>]] — <detail>
- [[knowledge/tools/<entity-2>]] — <detail>
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

Add new entries to `knowledge/_index.md` under the appropriate category (People, Companies, Tools, Concepts, Comparisons). Format:

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
  knowledge/tools/<name>.md
  knowledge/concepts/<name>.md

Updated:
  knowledge/people/<existing>.md (added <what>)

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
