---
title: Resolver — Routing Table
type: context
tags:
  - resolver
  - routing
  - filing
  - operations
created: {{DATE}}
updated: {{DATE}}
---

# Resolver

> First-match-wins routing for capture-types and subjects. Every brain-writing skill reads this file before creating any new page.
> Deterministic — no LLM judgment. Disambiguation rules handle edge cases. When unclassifiable, defer to user.

## Capture-type routing

Read top-to-bottom; first match wins.

| Input | Lives in | Then run |
|---|---|---|
| Meeting transcript / debrief | `meetings/YYYY-MM-DD-<topic>.md` | `meeting-ingest` |
| Daily report (SOD/EOD) | `reports/daily/YYYY-MM-DD-<type>.md` | `report-ingest` |
| Weekly report | `reports/weekly/YYYY-MM-DD-weekly.md` | `report-ingest` |
| Monthly report | `reports/monthly/YYYY-MM-DD-monthly.md` | `report-ingest` |
| Voice memo, transcript, pasted thinking | `inbox/YYYY-MM-DD-<topic>.md` | `knowledge-ingest` (or content-ingest if the vault has one) |
| Article, clipping, external doc | `inbox/YYYY-MM-DD-<topic>.md` | `knowledge-ingest` |
| Session log (per agent per day) | `sessions/YYYY-MM-DD-<agent>.md` | — |
| Dream-cycle report | `reports/dream-cycle/YYYY-MM-DD.md` | — |
| Onboarding completion report | `reports/onboard/YYYY-MM-DD-onboarding-complete.md` | — |

## Subject routing (knowledge graph)

When an ingest skill needs to create or update a page about a specific subject:

| Subject is a... | Lives in | Subtype |
|---|---|---|
| Specific human (teammate, client, public figure) | `knowledge/people/<kebab-name>.md` | `person` |
| Organization, business, brand | `knowledge/companies/<kebab-name>.md` | `company` |
| Software, product, service, tool | `knowledge/tools/<kebab-name>.md` | `tool` |
| Idea, pattern, methodology, framework | `knowledge/concepts/<kebab-name>.md` | `concept` |
| Synthesis across 3+ entities or concepts | `knowledge/comparisons/<kebab-name>.md` | `comparison` |

## Disambiguation rules

- **Founder who IS a company** (e.g. solo consultancy where founder name = brand): two pages, one in `people/`, one in `companies/`, linked via `founder_of` / `founded_by`. Example: a person named "Jane Doe" who runs a brand called "Jane Doe Coaching" gets `people/jane-doe.md` AND `companies/jane-doe-coaching.md`. If the founder has no independent professional identity beyond the brand, a single `people/` page is acceptable until the company grows distinct operations.

- **Tool that's also a company** (e.g. an LLM provider that builds an LLM product): company page in `companies/`, product page in `tools/`, linked via `built_by` / `builds`. Example: `companies/acme-corp.md` + `tools/acme-corp-exampletool.md`. The tool page is the primary subject for tool-specific facts; the company page is the primary subject for org-level facts (funding, team, strategy).

- **Reserved filename collision**: stems matching `claude`, `gemini`, `agents`, `readme`, `index` get prefixed with parent company (e.g. `claude` → `anthropic-claude`, `gemini` → `google-gemini`). Prevents macOS / Windows case-insensitive filesystems from auto-loading them as project instructions (e.g. `CLAUDE.md`, `AGENTS.md`).

- **Concept named after a person**: the concept page lives in `concepts/`; reference the person via `derived_from` typed link. Example: a methodology coined by "Bob Smith" gets `concepts/<methodology-name>.md` with `derived_from: [[knowledge/people/bob-smith]]`.

- **Person mentioned in body but not as attendee/author**: classify by signal:
  - **Attached action item or commitment** (e.g. "Brief Bob on X", "Cara to redo the audit") → create an inbox stub via `/knowledge-ingest`.
  - **Passing mention** (e.g. "checked with Dan") → unclassified mention; do not create a stub.

## When unclassifiable

The skill defers to the user with the candidate name + 1-line summary. **Never guesses.** The user picks the right directory or marks the candidate as not worth a page. Drop a placeholder in `inbox/` with a flag if needed.

## Filing-rules mandate

> Before creating any new page, read this file and file by **primary subject**, not by source format or skill name.

This mandate string lives at the top of every brain-writing skill (`knowledge-ingest`, `meeting-ingest`, `report-ingest`, and any other ingest skill the vault adds).
