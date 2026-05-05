---
name: triage
description: Walk auto-flagged action candidates across project plans and classify them into 7 categories — DONE, ACTIVE, DECISION-ABSORB, DECISION-PRESENT, DROP, MERGE, SUPERSEDED. Cleans up resolved entries, absorbs strategic decisions into project state.md, retains real open work in plan.md. Use weekly to monthly after dream-cycle accumulation.
tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

# Triage

Periodic cleanup of auto-flagged action candidates across project plans. Converts the noisy backlog produced by `meeting-ingest` Phase 4 into a focused list of truly-open work items, while preserving strategic decisions as durable context in project state.md files.

## When to use

- **Cadence:** weekly to monthly, after dream-cycle accumulation produces meaningful candidate volume.
- **First run:** when 50+ candidates have accumulated across active projects (typical 2-4 weeks after deployment).
- **On-demand:** before major project review or planning session.

## Trigger

- `/triage` — triage all projects with action candidates.
- `/triage <project-name>` — triage a single project.

## Configuration

```yaml
classification_taxonomy:
  - DONE                # Past-due action almost certainly happened. Remove.
  - ACTIVE              # Open work item, no clear resolution. Keep.
  - DECISION-ABSORB     # Strategic call/context not yet in plan/state. Move to state.md.
  - DECISION-PRESENT    # Already reflected in plan body or state.md. Remove.
  - DROP                # Duplicate, noise, mis-flagged. Remove.
  - MERGE               # Variant of an earlier candidate. Collapse, remove.
  - SUPERSEDED          # Overridden by a later candidate. Remove.

absorption_target_section: "## Strategic context (validated decisions, <date-range>)"
audit_log_section: "### Triage log"
```

## Workflow

### Phase 1: Discover scope

1. Walk `projects/*/plan.md` files; for each, find the `## Action candidates (auto-flagged)` section.
2. Count entries per project, total across projects.
3. If 0 candidates anywhere: report and exit.
4. Display: *"Found N candidates across M projects: project-a (X), project-b (Y), ..."*
5. If invoked without `<project-name>` argument, ask user: *"Triage all M projects, or pick subset?"*

### Phase 2: Read-only classification (parallel by project)

For each in-scope project, dispatch a subagent with:

- The 7-class taxonomy (above)
- The project's `plan.md` (Action candidates section + body for context)
- The project's `state.md` (so it can identify DECISION-PRESENT entries)
- Read-only Tools: Read, Grep, Glob

Each subagent classifies every candidate and returns a worksheet:

````
Project: <name>
- Candidate: "<source bullet text>"
  Source: [[meetings/YYYY-MM-DD-foo]]
  Class: ACTIVE | DONE | DECISION-ABSORB | DECISION-PRESENT | DROP | MERGE | SUPERSEDED
  Reason: <one line>
````

Aggregate worksheets. Present to user. Allow user to override individual classifications before applying.

### Phase 3: Apply Lane 1 (cleanup) + Lane 3 (retain)

Dispatch parallel subagents — one per project. Each subagent:

1. Reads its project's `plan.md`.
2. Removes entries classified as `DONE / DECISION-PRESENT / DROP / MERGE / SUPERSEDED` from `## Action candidates (auto-flagged)`.
3. Keeps `ACTIVE` and `DECISION-ABSORB` in place (Lane 2 will move ABSORB later).
4. Appends an entry to `### Triage log` subsection (create if missing) inside `## Action candidates`:

````
- **YYYY-MM-DD** — Initial triage of N candidates: X done, Y already-absorbed, Z drop, W merge, V superseded → removed. A active + B absorb retained for follow-up.
````

5. Bumps `updated:` field in plan.md frontmatter.

### Phase 4: Apply Lane 2 (absorption)

Dispatch parallel subagents — one per project. Different write target (state.md vs plan.md), so safe to parallelize alongside Phase 3 results.

Each subagent:

1. Re-classifies the worksheet's `DECISION-ABSORB` entries against the live plan.md + state.md (re-classification at write time prevents stale-data bugs).
2. For each confirmed absorb, formats a one-bullet summary with source link:

````
- **<short decision>** ([[meetings/YYYY-MM-DD-source]]) — <one-sentence why/context>.
````

3. Adds bullets to `## Strategic context (validated decisions, <date-range>)` section in state.md (creates section if missing; date-range is the candidates' source-date span).
4. Removes the absorbed entries from plan.md's `## Action candidates`.
5. Appends a Lane 2 entry to `### Triage log`:

````
- **YYYY-MM-DD** — Lane 2: B absorb entries moved into state.md § Strategic context. Remaining backlog is active-only.
````

6. Bumps `updated:` on both plan.md and state.md.

### Phase 5: Final report

Display:

````
Triage complete.
- N candidates triaged across M projects.
- A active retained in plan.md (real open work).
- B absorbed into state.md § Strategic context.
- C cleaned up (DONE/PRESENT/DROP/MERGE/SUPERSEDED).
- Triage log entries appended to all M plans.
- User overrides: <list any manual overrides for audit visibility>.
````

## Safety rules

- **Never parallelize within a single plan.** Read/write races on the same `## Action candidates` section will corrupt. Per-project subagents only.
- **Re-classification at write time.** Each Lane 2 subagent re-classifies candidates rather than trusting Phase 2's worksheet — prevents stale-data bugs when Phase 2 ran significantly earlier.
- **Triage log is append-only.** Never overwrite prior entries; the audit trail is the only record of what was destroyed and when.
- **No status changes on `state.md` `status:` field.** Triage cleans candidates and absorbs decisions; project status (active/paused/completed) remains user-only.

## What this skill does NOT do

- Promote inbox stubs. That's `/knowledge-ingest`.
- Edit project plan bodies outside `## Action candidates` and `### Triage log`.
- Run on plans without action candidates. Skips silently.
