#!/usr/bin/env python3
"""One-shot migration: legacy `type: <subtype-value>` → `type: meeting` + `subtype: <value>`.

Pre-Phase-1 meeting notes used the subtype value directly as `type:` (e.g. `type: l10`).
The Phase 1 frontmatter contract requires `type: meeting` with a separate `subtype:`.
This script does the mechanical conversion and bumps `updated:` to today.

Idempotent: meetings already shaped `type: meeting` are skipped.
"""
import re
import sys
from datetime import date
from pathlib import Path

MEETINGS_DIR = Path("{{VAULT_HOME}}/{{VAULT_NAME}}/meetings")
TODAY = date.today().isoformat()

LEGACY_TYPES = {
    "1on1", "advisory", "client", "client-1on1", "coaching-call",
    "external", "external-intro", "external-partner",
    "internal-1on1", "internal-finance", "internal-team", "internal-training",
    "l10", "standup", "team", "working-session",
}

migrated, skipped, errors = 0, 0, []

for f in sorted(MEETINGS_DIR.glob("*.md")):
    content = f.read_text()
    if not content.startswith("---\n"):
        errors.append((f.name, "no frontmatter"))
        continue
    end = content.find("\n---\n", 4)
    if end == -1:
        errors.append((f.name, "no frontmatter close"))
        continue
    fm = content[4:end]
    rest = content[end + 5:]

    type_match = re.search(r"^type:\s*([^\s]+)\s*$", fm, re.MULTILINE)
    if not type_match:
        errors.append((f.name, "no type: field"))
        continue
    type_val = type_match.group(1).strip("\"'")

    if type_val == "meeting":
        skipped += 1
        continue
    if type_val not in LEGACY_TYPES:
        errors.append((f.name, f"unknown type '{type_val}'"))
        continue
    if re.search(r"^subtype:", fm, re.MULTILINE):
        errors.append((f.name, "has subtype: already, manual review"))
        continue

    # Replace `type: <legacy>` with `type: meeting` + `subtype: <legacy>` immediately after
    new_fm = re.sub(
        r"^type:\s*[^\s]+\s*$",
        f"type: meeting\nsubtype: {type_val}",
        fm,
        count=1,
        flags=re.MULTILINE,
    )
    # Bump updated:
    new_fm = re.sub(
        r"^updated:.*$",
        f"updated: '{TODAY}'",
        new_fm,
        count=1,
        flags=re.MULTILINE,
    )
    f.write_text("---\n" + new_fm + "\n---\n" + rest)
    migrated += 1

print(f"Migrated: {migrated}")
print(f"Skipped (already canonical): {skipped}")
print(f"Errors / manual review: {len(errors)}")
for name, msg in errors:
    print(f"  - {name}: {msg}")
