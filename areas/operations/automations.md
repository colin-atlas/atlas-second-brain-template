---
title: Automations Registry
type: area
tags:
  - operations
  - automations
  - infrastructure
created: {{DATE}}
updated: {{DATE}}
---

# Automations Registry

Living registry of every scheduled or event-triggered automation across this brain and connected systems. Single source of truth for **what's automated, where it runs, what its health signal is, and whether it's currently firing**.

Adding a new automation? Append a row to the right table, fill in every column, and write a one-paragraph entry under "Automation details" below.

Pattern: every automation must produce a **health signal** — a dated artifact, log entry, or queryable status — that proves it ran successfully on a given day. Missing artifact = silent failure.

---

## Active automations

### Brain (vault)

| Name | Purpose | Host | Schedule | Health signal | Status | Last verified |
|---|---|---|---|---|---|---|
| `dream-cycle` | Nightly brain maintenance: auto-ingest, lint --fix, orphan/stale flag, session synthesis | local launchd / cron | 03:00 daily | `reports/dream-cycle/YYYY-MM-DD.md` | 🔘 not yet scheduled | — |
| Obsidian-Git auto-commit (recommended) | Snapshot vault changes to git | local Obsidian plugin | every 5 min on file change | git log entries | 🔘 not yet enabled | — |
| Obsidian-Git auto-push (recommended) | Push to private remote | local Obsidian plugin | every 5 min | most recent commit on `origin/main` matches local | 🔘 not yet enabled | — |

## Status legend

- 🟢 active and verified firing
- 🟡 scheduled, awaiting first run / verification
- 🔘 not yet scheduled / disabled
- 🔴 misfiring or stopped

## Automation details

(Add one paragraph per active automation describing what it does, where its config lives, and how to verify health.)
