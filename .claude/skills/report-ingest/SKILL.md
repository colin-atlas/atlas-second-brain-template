---
name: report-ingest
description: Ingest a daily / weekly / monthly report into the synthesized layers — update mentioned project states, append to area docs, and flag action candidates. Use when a report is filed in `reports/<period>/` and needs to update downstream tracking.
tools: Read, Write, Edit, Glob, Grep, Bash
---

> **Filing-rules mandate (from `RESOLVER.md`):** Before creating any new page, read `{{VAULT_HOME}}/{{VAULT_NAME}}/RESOLVER.md` and file by primary subject, not by source format.

# Report Ingest

Process a report in `reports/<period>/` into the synthesized layers of the brain.

## Configuration

```yaml
vault_owner:
  full_name: "{{VAULT_OWNER_FULL_NAME}}"        # e.g., "Jane Doe"
  short_name: "{{VAULT_OWNER_SHORT_NAME}}"      # what appears in author / attendee lists
  aliases: []                                   # additional name variants
```

## Trigger

- Manual: `/report-ingest <path>` or "ingest this report"
- Auto: invoked by `dream-cycle` for any report filed today that hasn't been ingested yet

## Input

A path to a report file under `reports/daily/`, `reports/weekly/`, or `reports/monthly/`. Frontmatter must include `type: report` and `date:` (YYYY-MM-DD). The report is expected to have sections like "What I worked on", "Decisions made", "Open threads", or equivalent — but the skill handles unstructured reports too.

## Workflow

### Phase 1: Validate input

1. Read the report completely.
2. Verify it lives under `reports/`. If not, refuse and direct the user to `RESOLVER.md`.

### Phase 2: Project mentions and status updates

For each `projects/<slug>/` directory:

1. Check if the project name (or `state.md` title) appears in the report body.
2. **If matched:**
   - Look for explicit status statements ("X is complete", "Y is paused", "Z is blocked"). If found, **flag** in the project's `## Action candidates (auto-flagged)` section — do NOT auto-edit the `status:` field in `state.md`. Status changes are too consequential for automation.
   - Look for action items, deferrals, or open threads mentioning the project. Append to the same section:

     ```markdown
     - **<date>** — <one-line summary>. Source: [[reports/<period>/<filename>]]. Status: pending review.
     ```
   - Update the project `state.md`'s `updated:` date.

### Phase 3: Area mentions

For each `areas/<slug>/` directory or top-level area page:

1. Check if the area name appears in the report.
2. If matched and the report mentions a substantive update (decision, new doc, learning), append a timeline entry to the area's most relevant living doc (e.g. `areas/finances/strategy.md`) under a `## Recent activity` section. Conservative — only if the update is concrete and not just a passing mention.

### Phase 4: People / company mentions

Same as `meeting-ingest` Phase 3: scan for entity mentions, append timeline entries with `mentioned_in` typed edges to existing pages. New people: stub to `inbox/` (never direct to `knowledge/people/`).

### Phase 5: Write synthesis block

Append to the report file (NOT touching anything above):

```markdown

<!-- generated: report-ingest do-not-edit -->
## Ingest summary (auto-generated YYYY-MM-DD)

- Project action candidates flagged: [[projects/<slug>/plan.md#action-candidates-auto-flagged]] (N)
- Areas updated: [[areas/<slug>/<doc>.md]]
- People/companies enriched: <count>
- Stubs created (review): [[inbox/...]]
<!-- /generated -->
```

If the synthesis block already exists from a prior ingest, **replace** it.

### Phase 6: Report to user

Output a one-screen summary similar to `meeting-ingest`'s.

## Rules

- **Status changes in `state.md` are flag-only.** Never auto-edit a project's `status:` field — that's a deliberate human decision.
- **Plan bodies are never edited.** Same as `meeting-ingest`.
- **Reports are write-once above the synthesis block.** Same as meetings.
- **Areas get conservative updates.** Only when a clear, substantive update is mentioned — not passing references.
- All typed edges follow the CLAUDE.md taxonomy.
- All filing decisions consult `RESOLVER.md`.
