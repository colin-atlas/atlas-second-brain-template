---
name: onboard
description: One-time cold-start setup for a freshly-cloned Atlas second brain. Validates context placeholders, orchestrates meeting import from the client's tool of choice, frequency-scans attendees, pre-creates knowledge/people pages, runs bulk meeting-ingest with the 30-day cutoff, and produces an onboarding report. Re-invocation is idempotent (skips already-complete phases).
tools: Read, Write, Edit, Glob, Grep, Bash, Task, AskUserQuestion
---

# Onboard

Single skill the EA invokes after `git clone` + basic placeholder fill-in. Walks through 7 phases producing a populated brain in one session.

## When to use

- **First run:** immediately after the EA fills `context/user.md`, `context/company.md`, `context/team.md`, and skill Configuration blocks.
- **Re-runs:** safe — idempotent. Use when adding more meetings later, or onboarding a new team member's data into an existing brain.

## Trigger

- `/onboard` — runs all 7 phases.

## Configuration

(Validates against the placeholders below, populated in CLAUDE.md and `context/` files.)

```yaml
required_placeholders_filled:
  - context/user.md           # {{EXEC_NAME}}, {{EXEC_ROLE}}, {{EXEC_COMPANY}}
  - context/company.md        # {{COMPANY_NAME}}, {{COMPANY_DESCRIPTION}}
  - context/team.md           # at least one teammate row
  - .claude/skills/meeting-ingest/SKILL.md   # {{VAULT_OWNER_FULL_NAME}}, {{VAULT_OWNER_SHORT_NAME}}
  - .claude/skills/report-ingest/SKILL.md
  - .claude/skills/dream-cycle/SKILL.md      # {{LAUNCHD_LABEL_PREFIX}}

frequency_thresholds:
  team_member_auto_promote: 1     # Anyone in team.md, any touch count
  non_team_auto_promote: 5        # Non-team with ≥5 touches
  non_team_confirm_range: [3, 4]  # Non-team with 3-4 touches → ask user
  inbox_below: 3                  # <3 touches → inbox stub

batching:
  max_meetings_per_subagent: 20   # Sequential batches; never parallel
```

## Workflow

### Phase 1: Validate context

1. Scan `context/user.md`, `context/company.md`, `context/team.md` for unfilled `{{...}}` placeholders.
2. Scan skill SKILL.md files for unfilled `{{VAULT_OWNER_FULL_NAME}}` etc.
3. If any unfilled placeholders found: produce a clear table of which file → which placeholder → suggested value. Refuse to proceed.
4. If clean: confirm with user *"Context validated. Proceeding to import setup."*
5. **No write ops.**

### Phase 2: Confirm scope of import

1. Ask user (use AskUserQuestion):
   - *"Which meeting tool do you use? Options: Fathom / Granola / Otter / Fireflies / other / skip"*
   - *"How many days of historical meetings to import? Default: 60"*
2. Display recommended import paths per tool:
   - **Fathom:** Composio connector available — `composio gmail-fetch ...` or manual JSON export from Fathom dashboard.
   - **Granola:** manual export — go to Granola → Settings → Export → JSON.
   - **Otter:** Composio connector available.
   - **Fireflies:** Composio connector available; or manual JSON export.
   - **other / skip:** Claude Code can guide custom import once told the tool name + format.
3. Record choices for Phase 3.
4. **No write ops yet.**

### Phase 3: Import meetings (interactive)

1. Hand off to Claude Code in interactive mode using the Phase 2 choices.
2. Claude Code orchestrates the actual import: API calls or guided manual upload.
3. Imported transcripts land in `meetings/YYYY-MM-DD-<topic>.md` with proper frontmatter:

```yaml
---
title: <Meeting topic>
type: meeting
subtype: <inferred: 1on1 / standup / sync / external / training / coaching / l10>
date: YYYY-MM-DD
attendees:
  - Name 1
  - Name 2
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

4. Report count: *"Imported N meetings spanning <date-range>."*
5. **Write op:** new files in `meetings/`.

### Phase 4: Frequency scan + pre-creation queue

1. Walk imported `meetings/`, extract attendees from frontmatter.
2. Normalize variants (e.g. "Jane D." → "Jane Doe" if Jane Doe is in team.md).
3. Cross-reference with `context/team.md` (parse the teammate roster).
4. Classify each unique attendee:
   - **Auto-promote (team)**: in team.md → auto-create regardless of touch count.
   - **Auto-promote (frequent)**: not in team.md AND ≥5 touches → auto-create.
   - **Confirm**: not in team.md AND 3-4 touches → ask user (AskUserQuestion): *"<Name> appeared N times. Promote to people/, drop in inbox/, or skip?"*
   - **Inbox**: <3 touches → inbox stub.
5. Skip the vault owner (their name is in `{{VAULT_OWNER_FULL_NAME}}` / aliases per skill Configuration).
6. Output a confirmation list before proceeding to Phase 5.
7. **No write ops in this phase** — generates the queue.

### Phase 5: Pre-create people pages

For each auto-promote + user-confirmed promote:

1. Create `knowledge/people/<kebab-name>.md`:

```markdown
---
title: <Full Name>
type: knowledge
subtype: person
tags:
  - person
  - <team | external>
created: YYYY-MM-DD
updated: YYYY-MM-DD
sources:
  - <list of [[meetings/<file>]] for the meetings they appeared in>
related: []
---

# <Full Name>

## Overview

<role from team.md, if available>

## Timeline

<empty — populated by /meeting-ingest in Phase 6>

## Related

<empty — populated as they connect to companies, tools, concepts>
```

2. For inbox-bound entries: create `inbox/YYYY-MM-DD-person-<kebab-name>.md` stubs.
3. Report counts: *"Pre-created M people pages, K inbox stubs."*
4. **Write op:** new files in `knowledge/people/` and `inbox/`.

### Phase 6: Bulk meeting-ingest

1. List imported `meetings/` files sorted by date (oldest first).
2. Batch them into groups of ≤20 meetings each.
3. For each batch, in sequence (NEVER parallel):
   - Dispatch a subagent with: the batch's meeting filenames, the meeting-ingest skill instructions, and full read access.
   - Wait for completion before dispatching next batch.
   - Display per-batch progress: *"Batch X/Y: ingesting Z meetings (oldest <date> → newest <date>)..."*
4. The 30-day Phase 4 cutoff (in meeting-ingest skill Configuration) automatically suppresses action candidates for old meetings.
5. **Write ops:** synthesis blocks in meetings, timeline appends to people/companies/tools, action-candidate sections in project plans.

### Phase 7: Final report + handoff

1. Compute stats:
   - N meetings ingested
   - M people pages (pre-created + stubs)
   - K companies created
   - J tools created
   - P project plans bootstrapped
   - L action candidates flagged across plans (only meetings within 30 days contributed)
   - S inbox stubs awaiting triage

2. Write `reports/onboard/YYYY-MM-DD-onboarding-complete.md`:

```markdown
---
title: Onboarding Complete — YYYY-MM-DD
type: report
subtype: onboard
tags: [onboarding, milestone]
date: YYYY-MM-DD
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Onboarding Complete

## Stats
- ...

## Pre-created people pages
- ...

## Inbox triage queue (S stubs)
- ...

## Recommended next steps
- Run `/triage` after 1-2 weeks of accumulation to clean action candidates.
- Promote recurring inbox stubs via `/knowledge-ingest <stub>`.
- Schedule the dream-cycle: see SETUP.md.
```

3. Display the report contents to the user.

## What `/onboard` does NOT do

- Set up the dream-cycle launchd schedule. That's a one-shot terminal step in SETUP.md.
- Run the first `/triage` pass. The user runs that separately.
- Promote inbox stubs to `knowledge/people/`. The user runs `/knowledge-ingest <stub>`.
- Auto-fix existing data. If the user has pre-existing files, the skill respects them — frequency scan still includes their attendees but Phase 5 skips already-existing files.

## Idempotency

Re-running `/onboard`:
- Phase 1: validates context (cheap).
- Phase 2: detects existing meetings, asks *"You have N meetings already. Import more, or proceed with existing?"*
- Phase 3: only imports new meetings (skips dates already covered).
- Phase 4-5: skips any people page that already exists.
- Phase 6: `meeting-ingest` is itself idempotent (already-ingested meetings are no-ops).

Re-running adds delta only.
