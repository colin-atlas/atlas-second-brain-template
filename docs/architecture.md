# Reference Architecture for an Executive / Company Brain

> Portable patterns for a second brain that scales from one executive to a managed-service operation. Written as rules, not instantiation. This is the architecture the `atlas-second-brain-template` implements.

## 1. Three-layer brain

A second brain has three layers: **captures**, **synthesized layers**, and **health signals**.

- **Captures** are write-once primary evidence: meetings, reports, session logs, inbox items, clippings.
- **Synthesized layers** are typed, queryable derivatives: people, companies, tools, concepts, comparisons, and any domain-specific graphs (e.g. a content graph for writing systems).
- **Health signals** are dated outputs of nightly maintenance: orphan reports, broken-link reports, freshness audits.

Captures never get edited after filing. Synthesized layers only receive *additive* updates from ingestion. Health-layer files document the state of the system over time, never the data itself.

### Subdivisions in the synthesized layer

The synthesized layer separates entity *types* into directories, not into one mixed bucket. At minimum:

- `knowledge/people/` — one page per human (teammate, client, public figure)
- `knowledge/companies/` — one page per organization
- `knowledge/tools/` — one page per software, product, or service
- `knowledge/concepts/` — patterns, ideas, methodologies
- `knowledge/comparisons/` — synthesis pages across 3+ entities

Why split: filing decisions become mechanical (a person → people/, a company → companies/) rather than judgment calls. Ingestion skills can route deterministically.

## 2. RESOLVER.md — the routing table for filing

The brain has one file at the vault root that maps **intent to location**. Every brain-writing skill consults it before creating a new page. The resolver does two things:

1. **Capture-type routing.** Tells the agent where a new raw input lives (`meetings/`, `reports/<period>/`, `inbox/`).
2. **Subject routing.** Tells ingest skills which directory under `knowledge/` a derived entity page belongs in.

The resolver is **deterministic** — first-match-wins, no model judgment. Disambiguation rules handle edge cases (e.g. a founder who IS a company). When the resolver can't classify a subject, the skill defers to the user instead of guessing.

### Filing-rules mandate

The single most important contract: every brain-writing skill begins with one sentence:

> Before creating any new page, read `RESOLVER.md` and file by primary subject, not by source format.

This prevents skills from internalizing their own filing assumptions over time. Drift gets caught at the source — the routing logic lives in one place, not 4 places.

## 3. Typed wikilinks + reciprocity enforcement

Wikilinks in the synthesized layer are **typed** in frontmatter, not bare:

```yaml
related:
  - link: "[[knowledge/people/jane-doe]]"
    type: founder_of
```

A small fixed taxonomy (~8 concepts, ~11 strings counting directional pairs like `founded_by`/`founder_of`) is preferred over a free-form vocabulary. Why fixed:

- **Mechanical filing.** Ingest skills emit known types, not LLM-improvised relationships.
- **Reciprocity enforcement.** A lint pass can verify every typed edge has its reciprocal on the other side. Free-form types make this impossible.
- **Drift control.** New types get debated and added to the taxonomy before use. Prevents "10 ways to say works at."

The lint skill enforces reciprocity in two modes: advisory by default (manual runs flag), auto-fix when invoked by the nightly dream-cycle (so reciprocity is a background concern, not a daily one).

## 4. Synthesis-bridge skill shape

A capture-to-synthesis pipeline needs **one ingest skill per capture type** — not one universal skill. The four canonical skills:

| Capture type | Lives in | Skill | What it produces |
|---|---|---|---|
| Meeting | `meetings/` | `meeting-ingest` | enriched people pages, entity timeline appends, project action-candidates |
| Report (SOD/EOD/weekly/monthly) | `reports/<period>/` | `report-ingest` | project state updates, area updates |
| Voice / transcript / pasted thinking | `inbox/` | `content-ingest` | takes/stories in content-graph + people/company `mentions` edges |
| Article / clipping / external doc | `inbox/` | `knowledge-ingest` | concept/tool/comparison/people/company pages |

All four open with the same filing-rules mandate (resolver lookup) and emit the same typed-wikilink shape. They differ in their **input parsing** (meetings have attendees and decisions; reports have status sections; transcripts have voice signatures) and their **synthesis shape** (which directories they enrich).

> The `atlas-second-brain-template` ships with `meeting-ingest`, `report-ingest`, and `knowledge-ingest`. The `content-ingest` skill (writing-system / content-graph layer) is a separate addon — relevant for clients who publish (founders with newsletters, coaches, content-led businesses) and not built into the core template.

### Configuration block

Each ingest skill needs a small Configuration section near the top covering two platform realities:

- **Vault-owner identity.** One human is the user, not a subject of synthesis. Their name (and common variants — first name, full name) is enumerated and **skipped** from attendee/author enumeration. Without this, every meeting generates a stub for the vault owner. Configure as a hard-coded list at the top of each skill, not as fuzzy detection.
- **Reserved-filename stems.** Case-insensitive filesystems (macOS, Windows by default) collide with project-instruction filenames. Stubs whose case-folded name matches `claude`, `gemini`, `agents`, `readme`, or `index` get auto-loaded as instructions. Add a global guard: kebab-name → if collision, prefix with parent company or category (e.g. `claude` → `anthropic-claude`, `gemini` → `google-gemini`). Apply to ALL stub creation across all phases of all skills.

### Four guarantees every ingest skill makes

1. **Captures are never edited above the auto-generated synthesis block.** The user's hand-written content is sacred.
2. **New people never get created directly.** Stubs go through `inbox/` first; `knowledge-ingest` promotes after review. This prevents fuzzy-name duplicates.
3. **Project plan bodies are never edited.** Action candidates go to a dedicated `## Action candidates (auto-flagged)` section.
4. **Re-runs are idempotent.** Every phase that appends content (timeline entries, typed edges, action candidates) checks for the source filename's prior presence before writing. Re-running an already-ingested capture is a no-op. Without this, batch re-runs and dream-cycle re-attempts duplicate everything.

These four guarantees are the contract that lets ingest skills run unattended without trust degrading.

### Operational rules

Beyond the guarantees, three rules shape what gets captured vs. dropped:

- **Stale-cutoff for project action candidates.** Captures older than ~30 days skip Phase 4 (project action-candidate generation) entirely. Old action items are mostly rotted (already done or moot); flagging them on active plans creates noise. Phase 2 and Phase 3 (people + entity timelines) still fire — those are inherently historical observations and remain valuable for the graph. The cutoff value is configurable per deployment; 30 days fits a typical weekly-planning rhythm.
- **plan.md auto-bootstrap (conditional).** When a project is matched in a capture but the project has no `plan.md`, bootstrap a minimal one — but only when there are actionable candidates to insert. Don't create empty plan.md files for projects mentioned in passing. The minimal shape: frontmatter (`type: project`, dates), a `# Plan` heading, and the `## Action candidates (auto-flagged)` section.
- **Body-person heuristic.** When a person is mentioned in a capture body but not as an attendee/author, classify by signal: **attached action item or commitment** (e.g. "Brief Bob on X", "Cara to redo the audit") → create an inbox stub; **passing mention** (e.g. "checked with Dan") → drop in unclassified mentions. Without this rule, ingest defaults to either over-stubbing or under-capturing.

## 5. Dream cycle — nightly maintenance

Synthesis bridges create new pages and edges every day. Without a counter-pressure, the brain accumulates orphans, broken reciprocals, and stale stubs. The dream cycle is the brain's **garbage collector and synthesizer in one** — it runs unattended each night and produces a dated health report.

### Five phases, in order

1. **Auto-ingest** today's captures (meetings, reports) that don't already have a synthesis block. Bounded by a 2-hour minimum age to avoid racing in-progress edits.
2. **Lint --fix** — frontmatter fixes, typed-link reciprocity auto-add, broken-wikilink flagging.
3. **Backlink health** — reciprocity check beyond what lint catches (capture pages → entity pages).
4. **Stale flag** — active projects with old `updated:`, untriaged inbox, knowledge pages with low connectivity and old timestamps.
5. **Session synthesis** — extract 3–5 notable items from today's session logs, drop as candidates into `inbox/` for next-morning review (never auto-ingest these — they're the deliberate human-in-loop boundary).

The cycle outputs `reports/dream-cycle/YYYY-MM-DD.md` every run. The dated-file pattern is itself a health signal: missing files indicate a scheduling or execution failure.

### What dream cycle does NOT do

- **Tier escalation** (stubs → web-enriched pages → full-pipeline pages). Optional pipeline phase. The dream cycle just flags `tier: 3` stubs; it doesn't promote them.
- **Auto-promotion of session items into the brain.** Session synthesis writes to `inbox/`, full stop. The user triggers `/content-ingest` or `/knowledge-ingest` after review.
- **Status changes on project `state.md`.** Action candidates are flagged in `plan.md`'s dedicated section; `status:` field changes always require human consent.
- **Stale-cutoff for action candidates.** That's a *skill-level* concern (the 30-day cutoff in `meeting-ingest`'s Phase 4), not dream-cycle scope. The dream cycle reports stale items but doesn't suppress them.

## 6. Triage cycle — the other half of synthesis

Ingestion is half the loop; **triage** is the other half. Without triage, action-candidate sections bloat indefinitely as captures keep arriving. Triage runs periodically (weekly to monthly cadence depending on capture volume) and converts the auto-flagged backlog into one of seven classifications.

### Seven-class taxonomy

| Class | Meaning | Disposition |
|---|---|---|
| `DONE` | Past-due action that almost certainly happened | Remove |
| `ACTIVE` | Open work item, no clear resolution | Keep (truly pending) |
| `DECISION-ABSORB` | Strategic call/context, not yet reflected in plan/state | Move to state.md, then remove from candidates |
| `DECISION-PRESENT` | Already reflected in plan body or state.md | Remove (substance preserved elsewhere) |
| `DROP` | Duplicate, noise, mis-flagged for this project | Remove |
| `MERGE` | Variant of an earlier candidate, same idea | Collapse, remove |
| `SUPERSEDED` | Overridden by a later candidate | Remove |

The fundamental insight: most auto-flagged candidates are **decisions**, not to-dos. Plans should not carry decisions as "pending review" forever; decisions belong in state.md once validated.

### Three-lane execution

Triage runs in three lanes, in order:

1. **Cleanup lane.** Remove `DONE` / `DECISION-PRESENT` / `DROP` / `MERGE` / `SUPERSEDED` entries from `## Action candidates (auto-flagged)`. No judgment-output needed; these are purely tidied.
2. **Absorption lane.** `DECISION-ABSORB` entries get summarized as bullets and added to a new or existing `## Strategic context (validated decisions, <date-range>)` section in the project's state.md. This gives state.md a "what's true now and why" layer. After absorption, the source candidates are removed from plan.md.
3. **Retain lane.** `ACTIVE` entries stay in plan.md as the actually-open backlog.

### Audit trail

Each triage pass appends an entry to a `### Triage log` subsection inside `## Action candidates (auto-flagged)`:

```
- **YYYY-MM-DD** — Initial triage of N candidates: X done, Y already-absorbed, Z drop, W merge, V superseded → removed. A active + B absorb retained for follow-up.
- **YYYY-MM-DD** — Lane 2: B absorb entries moved into state.md § Strategic context. Remaining backlog is active-only.
```

The log is essential. Triage is destructive; the log is the only record of what was removed when.

### Parallelization

Per-project triage is mostly independent — different state.md, different plan.md. Parallel subagent dispatch is safe across plans. Pair plans by candidate volume (e.g. one large plan per subagent, or a couple of small plans together) to balance runtime. The constraint: **don't parallelize within a single plan** — read/write races on the same `## Action candidates` section will corrupt the result.

### When to run

- **First run** when a backlog has accumulated meaningfully (e.g. 50+ candidates across the active projects). The initial pass surfaces the absorbed-decisions pattern most clearly.
- **Recurring** weekly to monthly, after the dream-cycle's accumulation. Volume drops dramatically once the initial pass is done.
- **On-demand** before any major project review or planning session.

## 7. Pre-creation strategy for cold starts

When deploying this architecture into an existing organization with historical capture data, the naive path is "run all historical captures through ingest." This produces a catastrophic number of inbox stubs and almost no enrichment, because `knowledge/people/` starts nearly empty.

The fix: **pre-create the knowledge graph's high-frequency nodes before bulk historical ingest.**

### Pre-creation procedure

1. **Org chart from the source-of-truth file.** Read `context/team.md` (or equivalent) to get role + reporting relationships for the operating organization.
2. **Frequency scan over historical captures.** Walk the capture corpus (meetings, etc.), extract all attendee names, normalize variants/aliases, count occurrences. Output: ranked list of unique humans by capture-touch count.
3. **Cross-reference.** People appearing ≥3 times in the corpus that are also in the org chart → strong promotion candidates. Names appearing ≥3 times *not* in the org chart → ask the user to disambiguate (recurring external contacts, terminated former teammates, etc.).
4. **Pre-create at scale.** For confirmed recurring nodes, create `knowledge/people/<kebab-name>.md` directly with minimal content (role, reporting line, recurring-meeting cadence) and a `## Timeline` section that the ingest skill will populate.
5. **Then run bulk historical ingest.** Most attendees now hit the enrichment path (timeline + typed edges to existing pages) instead of the stub path. Stub creation drops by an order of magnitude.

### Why this matters

The economics: with no pre-creation, ingesting 150 meetings might create 250+ inbox stubs that all need manual `/knowledge-ingest` promotion afterward. With pre-creation of ~20 high-frequency nodes, the same 150 meetings produce ~80 inbox stubs (mostly truly-one-off contacts, which deserve the lighter-weight stub path).

This is also why the **vault-owner skip** in Section 4's Configuration is non-optional — the vault owner appears in 100% of meetings; without the skip they'd dominate the stub-creation budget.

> The `/onboard` skill in this template orchestrates the full pre-creation procedure as Phases 4-5 (frequency scan + classify + user-confirm + pre-create), then runs Phase 6 bulk meeting-ingest. One command, end-to-end.

## 8. Migration pattern for legacy data

Adopting this architecture into an existing organization means inheriting historical data that doesn't follow the canonical contracts: legacy frontmatter shapes, missing fields, ad-hoc filing decisions. Two-part strategy:

### Part 1 — Permissive skill validation as backup

Each ingest skill's input-validation phase (Phase 1 in the canonical workflow) accepts both the canonical shape (`type: meeting + subtype: <value>`) AND a configurable list of legacy shapes (`type: 1on1`, `type: l10`, etc.) that are semantically the same. This lets historical files flow through ingest immediately, without a blocking migration step.

The legacy list is documented in the skill itself, not hidden in tribal knowledge. New deployments inherit a starting list and prune it as the corpus is migrated.

### Part 2 — One-shot migration script

For each shape that needs canonicalizing, write an idempotent migration script that:

- Walks the relevant directory (`meetings/`, `reports/`, etc.)
- Parses each file's frontmatter
- Converts legacy shapes to canonical (e.g. `type: l10` → `type: meeting` + `subtype: l10`)
- Bumps `updated:` to today
- Skips files already in canonical shape (idempotent)
- Reports counts: migrated, skipped, errors

Reference implementation in this template: [`scripts/migrate-meeting-frontmatter.py`](../scripts/migrate-meeting-frontmatter.py).

### Why both

The permissive validation ensures the system is usable immediately; the migration script ensures the corpus eventually converges to canonical shape. Skipping either creates trouble: validation-only leaves the corpus permanently mixed; script-only blocks adoption until migration completes (and complicates partial-migration states).

### Where it runs

Three viable hosts (cloud-scheduled, local launchd, agent VPS). Pick by reliability of the vault sync — the dream cycle needs the vault to be in a known-good state when it runs. A remote-scheduled cycle reading a stale local sync is worse than no cycle.
