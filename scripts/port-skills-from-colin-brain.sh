#!/usr/bin/env bash
# Port hardened skills from colin-brain into the template.
# Atlas-internal: run when shipping a new template version.
# Replaces Colin-specific tokens with {{placeholders}}. Does not auto-commit.

set -euo pipefail

SOURCE_ROOT="${SOURCE_ROOT:-$HOME/colin-brain}"
TEMPLATE_ROOT="${TEMPLATE_ROOT:-$HOME/projects/atlas-second-brain-template}"
SKILLS=(knowledge-ingest meeting-ingest report-ingest dream-cycle lint)

if [[ ! -d "$SOURCE_ROOT/.claude/skills" ]]; then
  echo "ERROR: source skills dir not found: $SOURCE_ROOT/.claude/skills" >&2
  exit 1
fi

if [[ ! -d "$TEMPLATE_ROOT/.claude/skills" ]]; then
  echo "ERROR: template skills dir not found: $TEMPLATE_ROOT/.claude/skills" >&2
  exit 1
fi

for skill in "${SKILLS[@]}"; do
  src="$SOURCE_ROOT/.claude/skills/$skill"
  dst="$TEMPLATE_ROOT/.claude/skills/$skill"

  if [[ ! -d "$src" ]]; then
    echo "SKIP: $skill (not found in source)" >&2
    continue
  fi

  echo "Porting $skill..."
  rm -rf "$dst"
  cp -R "$src" "$dst"

  # Token substitutions (Colin-specific -> {{placeholder}}).
  # Order matters:
  #   - "Colin Pal" must run BEFORE the standalone "Colin" word-boundary substitution,
  #     otherwise it becomes "{{VAULT_OWNER_SHORT_NAME}} Pal".
  #   - "Atlas Assistants" must run BEFORE the standalone "Atlas" word-boundary
  #     substitution, otherwise it becomes "{{VAULT_OWNER_COMPANY}} Assistants".
  #   - "com.colinpal.colin-brain" must run BEFORE the "colin-brain" substitution,
  #     otherwise the launchd label becomes "com.colinpal.{{VAULT_NAME}}".
  # Word boundaries use BSD sed syntax ([[:<:]] / [[:>:]]) for macOS portability;
  # GNU sed also accepts these via the POSIX character-class names.
  find "$dst" -type f \( -name '*.md' -o -name '*.py' -o -name '*.sh' \) -print0 |
    while IFS= read -r -d '' file; do
      sed -i.bak \
        -e 's/Colin Pal/{{VAULT_OWNER_FULL_NAME}}/g' \
        -e 's/[[:<:]]Colin[[:>:]]/{{VAULT_OWNER_SHORT_NAME}}/g' \
        -e 's/Atlas Assistants/{{VAULT_OWNER_COMPANY}}/g' \
        -e 's/[[:<:]]Atlas[[:>:]]/{{VAULT_OWNER_COMPANY}}/g' \
        -e 's|com\.colinpal\.colin-brain|{{LAUNCHD_LABEL_PREFIX}}|g' \
        -e 's|colin-brain|{{VAULT_NAME}}|g' \
        -e 's|/Users/colinpal|{{VAULT_HOME}}|g' \
        -e 's|colin@colinpal\.com|{{VAULT_OWNER_EMAIL}}|g' \
        "$file"
      rm -f "$file.bak"
    done
done

echo ""
echo "Port complete. Diff against committed template:"
cd "$TEMPLATE_ROOT"
git status -- .claude/skills/
echo ""
echo "Review changes before committing."
