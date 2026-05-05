---
name: dream-cycle
description: Nightly maintenance pass that auto-ingests today's captures, enforces graph health (lint --fix, typed-link reciprocity, backlinks, orphans), flags stale content, and synthesizes today's session logs into candidate inbox items. Outputs a dated report to `reports/dream-cycle/YYYY-MM-DD.md`.
tools: Read, Write, Edit, Glob, Grep, Bash, SlashCommand
---

# Dream Cycle

The brain's nightly maintenance pass. Runs unattended (cron / Claude Code routine). Each cycle outputs a dated report so degradation is visible.

## Trigger

- Manual: `/dream-cycle` or "run the dream cycle"
- Auto: scheduled nightly (see `SETUP.md` for launchd/cron scheduling instructions; the launchd plist label uses `{{LAUNCHD_LABEL_PREFIX}}.dream-cycle`)

## Workflow

Five phases, run in order. Each phase writes a section to the daily report.

### Phase 0: Auto-ingest qualifying captures

Before any maintenance, ingest captures that have been filed today and not yet synthesized.

1. **Meetings:** find files in `meetings/` filed today (`created:` field or filesystem mtime), older than 2 hours, that **do not** contain `<!-- generated: meeting-ingest do-not-edit -->`. For each, invoke `/meeting-ingest <path>` via the SlashCommand tool.
2. **Reports:** same logic against `reports/{daily,weekly,monthly}/`. For each qualifying file, invoke `/report-ingest <path>` via the SlashCommand tool.

Skip files with the synthesis block already present (idempotent).

### Phase 1: lint --fix

Run the `lint` skill in fix mode (it's already invoked with `--fix` from this skill — typed-link reciprocity auto-fixes). Capture the output. Summarize changes (frontmatter additions, broken-link flags, reciprocity additions) into the daily report.

### Phase 2: Backlink health (additional to lint)

Beyond what lint catches:

- For every page in `knowledge/`, verify each typed `related:` entry's reciprocal exists on the target. (lint Phase 8 does this — this section reports the result, doesn't re-run.)
- For every page in `meetings/` and `reports/`, verify each `[[wikilink]]` in the body has a reciprocal entry in the target's `related:` (or at least a passing mention). Flag missing.

### Phase 3: Orphan flag

For pages in `knowledge/people/`, `knowledge/companies/`, `knowledge/tools/`, `knowledge/concepts/`, `knowledge/comparisons/`:

- Count inbound wikilinks (any direction).
- Pages with **0 inbound** are orphans. List them.
- Pages with **1 inbound and the inbound is `mentions` only** are weakly connected. List them.
- Pages with `tier: 3` frontmatter (stubs from earlier ingest) are still weak — list them as "needs enrichment."

These are flagged, not auto-fixed. Tier escalation happens in phase 2 of the project.

### Phase 4: Stale flag

- Active project `state.md` with `status: active` and `updated:` > 30 days old → flag.
- Inbox items > 14 days with `ingested: false` → flag (matches existing lint Phase 4).
- Knowledge pages with `updated:` > 180 days and inbound count < 3 → flag (could be obsolete).

### Phase 5: Session synthesis

For each file in `sessions/` matching today's date (`YYYY-MM-DD-*.md`):

1. Read the session log.
2. Extract 3–5 notable items: original thinking, surprising decisions, candidate takes, unresolved threads worth surfacing.
3. For each item, write a candidate inbox file: `inbox/YYYY-MM-DD-from-session-<slug>.md` with `ingested: false` and a one-line description. The user reviews next morning and triggers `/content-ingest` or `/knowledge-ingest` as appropriate.

Do NOT auto-ingest these. The session-to-inbox handoff is the deliberate boundary — {{VAULT_OWNER_SHORT_NAME}} reviews before they enter the brain proper.

### Phase 6: Write the daily report

Write `reports/dream-cycle/YYYY-MM-DD.md`:

```markdown
---
title: Dream Cycle — YYYY-MM-DD
type: report
subtype: dream-cycle
date: YYYY-MM-DD
tags:
  - dream-cycle
  - maintenance
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Dream Cycle — YYYY-MM-DD

## Phase 0 — Auto-ingest

- Meetings auto-ingested: <list>
- Reports auto-ingested: <list>
- Skipped (already synthesized): <count>

## Phase 1 — Lint --fix

- Frontmatter fields added: <count> across <file count> files
- Broken wikilinks flagged: <count> (no auto-fix)
- Typed-link reciprocity auto-fixed: <count>

## Phase 2 — Backlink health

- Reciprocity violations remaining: <count>
- Capture pages with un-reciprocated wikilinks: <list>

## Phase 3 — Orphans and weak connections

- Orphan pages (0 inbound): <list>
- Weakly connected (mentions-only): <list>
- Stubs needing enrichment (tier: 3): <list>

## Phase 4 — Stale content

- Active projects with stale state.md: <list>
- Untriaged inbox > 14d: <list>
- Knowledge pages > 180d with low connectivity: <list>

## Phase 5 — Session synthesis

- Sessions read: <list>
- Candidate inbox items written: <list>

## Health summary

- Auto-ingested today: <N>
- Issues fixed automatically: <N>
- Issues flagged for review: <N>
- Overall status: green / yellow / red
```

Status thresholds:
- **green:** zero broken wikilinks, zero un-reciprocated typed links, fewer than 5 orphans, fewer than 3 stale items.
- **yellow:** any of the above is non-trivially elevated.
- **red:** broken wikilinks > 5 OR cycle failed mid-phase.

## Output to user

Print a one-screen summary in the same shape as the daily report, plus a link to the full file. If status is yellow or red, surface the top 3 issues at the top of the summary.

## Rules

- **All phases are read-mostly except Phase 1 lint --fix.** No silent rewrites of compiled-truth content.
- **Auto-ingest is bounded.** Files older than 2 hours and missing the synthesis block — that's the whole filter. Edge cases (in-progress edits, partial files) tolerate by skipping.
- **Session synthesis writes to `inbox/`, never to `knowledge/`.** The boundary holds.
- **Daily report is always written**, even if every phase passes clean — the existence of the dated file is itself a health signal.
- **Sub-skill invocations use SlashCommand.** Phase 0 calls `/meeting-ingest` and `/report-ingest` via the SlashCommand tool — never inlined and never via shell. This preserves the contract that each ingest skill writes its own synthesis block and dedupes correctly.
