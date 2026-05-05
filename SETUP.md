# Atlas Second Brain — EA Setup Runbook

The operational playbook for an EA driving onboarding. Execute these steps in order during the client setup engagement.

## 1. Pre-clone prep (intake)

Gather from the intake call:

- Exec full name, short name (what appears in attendee lists), email
- Exec role + company name + company description (1-2 sentences)
- Communication preferences (direct vs elaborate, bullet vs prose, batch vs real-time, voice/tone)
- Meeting recording tool (Fathom / Granola / Otter / Fireflies / other)
- Retention horizon (how many days of history to import — default 60)
- Team roster (name + role + reporting line for each teammate)

## 2. Clone + fill placeholders

Clone the template to the exec's preferred location (default: `~/brain/`).

Fill the following placeholders. Use `grep -rln '{{' ~/brain` to find every unfilled file.

### Exec-facing placeholders (CLAUDE.md, context/)

| File | Placeholders |
|---|---|
| `CLAUDE.md` | `{{EXEC_NAME}}`, `{{EXEC_ROLE}}`, `{{EXEC_COMPANY}}`, `{{COMMUNICATION_STYLE}}`, `{{DECISION_STYLE}}`, `{{UPDATE_CADENCE}}`, `{{VOICE_TONE}}` |
| `context/user.md` | exec personal details |
| `context/company.md` | company details, mission, ICP |
| `context/icp.md` | ideal customer profile (if applicable) |
| `context/brand.md` | brand voice/positioning (if applicable) |
| `context/team.md` | one row per teammate (name, role, reports-to) |
| `RESOLVER.md` | `{{DATE}}` (frontmatter created/updated) |
| `knowledge/_index.md` | `{{DATE}}` |
| `projects/project-index.md` | `{{DATE}}` |
| `areas/operations/automations.md` | `{{DATE}}` |

### Skill-engine placeholders (.claude/skills/)

| File | Placeholders |
|---|---|
| `.claude/skills/meeting-ingest/SKILL.md` | `{{VAULT_OWNER_FULL_NAME}}`, `{{VAULT_OWNER_SHORT_NAME}}`, `{{VAULT_NAME}}`, `{{VAULT_HOME}}`, `{{VAULT_OWNER_COMPANY}}` |
| `.claude/skills/report-ingest/SKILL.md` | same |
| `.claude/skills/knowledge-ingest/SKILL.md` | same |
| `.claude/skills/dream-cycle/SKILL.md` | same + `{{LAUNCHD_LABEL_PREFIX}}` (e.g. `com.acme.brain`) |
| `.claude/skills/lint/SKILL.md` | same as meeting-ingest |
| `.claude/skills/onboard/SKILL.md` | typically no placeholders, but check |
| `.claude/skills/triage/SKILL.md` | typically no placeholders, but check |

### One-shot fill (recommended)

You can fill the most common skill-engine placeholders in bulk with sed (after backing up):

```bash
cd ~/brain
sed -i '' \
  -e 's/{{VAULT_OWNER_FULL_NAME}}/Jane Doe/g' \
  -e 's/{{VAULT_OWNER_SHORT_NAME}}/Jane/g' \
  -e 's/{{VAULT_OWNER_COMPANY}}/Acme Corp/g' \
  -e 's/{{VAULT_NAME}}/brain/g' \
  -e 's|{{VAULT_HOME}}|/Users/jane|g' \
  -e 's/{{LAUNCHD_LABEL_PREFIX}}/com.acme.brain/g' \
  CLAUDE.md RESOLVER.md $(find .claude/skills -name '*.md')
```

Verify after: `grep -r '{{' ~/brain --include='*.md' | head` should return only `{{DATE}}` and `{{EXEC_*}}` entries (which the EA fills by hand to capture the exec-specific tone).

## 3. Run `/onboard`

```bash
cd ~/brain
claude
```

Then in Claude Code:

```
/onboard
```

What to expect:

- **Phase 1** (instant): validates placeholders are filled. Refuses if not.
- **Phase 2** (interactive, ~2 min): asks meeting tool + days-back. Lists import options.
- **Phase 3** (5-30 min depending on tool): imports historical meetings. Manual export usually fastest if Composio connector isn't available for the chosen tool.
- **Phase 4** (interactive, 5-15 min): asks about non-team recurring contacts (3-4 touches, not in team.md). Default: drop in inbox unless clearly company-relevant.
- **Phase 5** (instant): pre-creates `knowledge/people/` pages from team + confirmed promotes.
- **Phase 6** (variable, 7-35 min per 20-meeting batch): runs bulk meeting-ingest. For 60 days = 1-3 batches typically. For 90+ days, 4-8 batches.
- **Phase 7** (instant): writes `reports/onboard/<date>-onboarding-complete.md`.

If a phase errors, you can re-run `/onboard` — it's idempotent and skips already-complete phases.

## 4. Schedule the dream-cycle

The dream-cycle is the brain's nightly maintenance pass. Without it, the brain accumulates orphans and broken reciprocals over time.

### macOS (launchd)

Create `~/Library/LaunchAgents/{{LAUNCHD_LABEL_PREFIX}}.dream-cycle.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>{{LAUNCHD_LABEL_PREFIX}}.dream-cycle</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/local/bin/claude</string>
    <string>/dream-cycle</string>
  </array>
  <key>WorkingDirectory</key>
  <string>{{VAULT_HOME}}/brain</string>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>3</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>{{VAULT_HOME}}/Library/Logs/brain-dream-cycle.log</string>
  <key>StandardErrorPath</key>
  <string>{{VAULT_HOME}}/Library/Logs/brain-dream-cycle.log</string>
</dict>
</plist>
```

Load: `launchctl load ~/Library/LaunchAgents/{{LAUNCHD_LABEL_PREFIX}}.dream-cycle.plist`.

Verify: `launchctl list | grep dream-cycle`.

### Linux (cron)

Add to crontab (`crontab -e`):

```
0 3 * * * cd ~/brain && /usr/local/bin/claude /dream-cycle >> ~/.local/log/brain-dream-cycle.log 2>&1
```

### Windows

Use Task Scheduler. Adapt the cron pattern to a daily 03:00 trigger running `claude /dream-cycle` from the vault directory.

### Verify next morning

Check `reports/dream-cycle/YYYY-MM-DD.md` was created (with today's date). Missing file = silent failure; investigate logs.

## 5. Inbox stub triage post-onboarding

`/onboard` Phase 4 drops <3-touch contacts as `inbox/YYYY-MM-DD-person-<name>.md` stubs. Most stay there. Promote only those who:

- Become recurring contacts after onboarding (track over 2-4 weeks)
- Are on the exec's known calendar going forward
- Are core team or vendor contacts the exec interacts with regularly

Promote with: `/knowledge-ingest inbox/<file>.md`.

## 6. First triage cycle (week 2)

Run `/triage` 1-2 weeks after onboarding. Expected first-triage pattern (based on Colin's reference run on 369 candidates → 76 active):

- ~50-60% of action candidates are DECISION-ABSORB (strategic context that absorbs into state.md).
- ~25-35% are DONE (already happened by the time you triage).
- ~10-20% are ACTIVE (real open work).
- Remainder (DROP / MERGE / SUPERSEDED) is small.

The triage skill walks you through classification + 3-lane application. Approves/overrides happen interactively before write.

## 7. Optional: Obsidian Sync + Obsidian Git

For multi-device + version history:

- **Obsidian Sync** ($10/mo, official): real-time multi-device sync. Setup: install plugin, enable in Obsidian Settings.
- **Obsidian Git** (free, recommended): auto-commit + push to a private GitHub/GitLab repo every 5 min. Setup: install plugin, configure remote, enable auto-commit/auto-push intervals to 5.

Both are recommended for clients who want resilience + cloud automations.

## Troubleshooting

- **`/onboard` Phase 1 refuses to proceed:** unfilled placeholders. Run `grep -r '{{' ~/brain --include='*.md'` to find them.
- **Dream-cycle didn't run overnight:** check `~/Library/Logs/brain-dream-cycle.log` (macOS) or `~/.local/log/brain-dream-cycle.log` (Linux). Common causes: launchd not loaded, claude binary path wrong, working dir wrong.
- **Meeting-ingest creating duplicate timeline entries:** indicates idempotency check broke. File a bug — should be no-op for already-ingested meetings.
- **Triage taking forever:** dispatch parallel subagents per project. Never within a single project (race conditions).
