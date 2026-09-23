#!/usr/bin/env bash
# check-ucode-style.sh — enforce OPENWIFI_CODING_GUIDELINES.md §3, §5 and §6 on
# the files this PR touches.
#
# This repo is ucode + YAML schema (no C), so it replaces wlan-ap's
# check-c-style.sh. The rules it covers:
#
# HARD FAILURES (exit 1):
#   - NEW .uc files must carry an SPDX-License-Identifier        (§3)
#   - ADDED .uc lines must not use spaces for indentation        (§5: tabs)
#   - generated files hand-edited without their .yml source      (§6)
#
# WARNINGS (annotate, don't fail):
#   - NEW .uc module without "use strict";                       (§5)
#
# Like the wlan-ap original, this intentionally does NOT lint pre-existing
# code — only what the PR adds — so legacy files don't block contributors.
#
# NOTE: §5 also asks for 'let' over bare globals, JSDoc on non-trivial
# functions, null-guards and assert() for invariants. Those are judgement
# calls left to review; only the two mechanical rules are enforced here.
#
# Findings are emitted as file/line annotations so they render inline on the PR
# diff, and each message repeats "path:line" in its text because the workflow
# strips annotation properties when folding these lines into the PR comment.

# 'set -e' is deliberately omitted (the wlan-ap original uses -euo): the
# '[ x = y ] && arr+=(...)' idioms below legitimately return non-zero, which
# would abort the script under -e. Failures are tracked via $fail instead.
set -uo pipefail

BASE_SHA="${BASE_SHA:?BASE_SHA not set}"
HEAD_SHA="${HEAD_SHA:?HEAD_SHA not set}"

# How many offending lines to report per file before collapsing the rest.
MAX_REPORT=10

fail=0
err()  { echo "::error::$*"; fail=1; }
warn() { echo "::warning::$*"; }

# err_at <file> <line> <message…> — annotation anchored to a line of the diff.
err_at() {
  local f="$1" l="$2"
  shift 2
  echo "::error file=$f,line=$l::$*"
  fail=1
}

# Keep a quoted source line short so one runaway line can't flood the comment.
trunc() {
  local s="$1" max=80
  if [ "${#s}" -gt "$max" ]; then
    printf '%s…' "${s:0:max}"
  else
    printf '%s' "$s"
  fi
}

# Three-dot range = diff against the merge base. With the two-dot form, a PR
# whose base branch has moved on would also be judged on files that only the
# base branch touched (base.sha is the base-branch tip at event time, not the
# branch point).
RANGE="${BASE_SHA}...${HEAD_SHA}"

# ---------------------------------------------------------------
# 1. Generated artefacts must come from the .yml sources (§6)
# ---------------------------------------------------------------
# generate.sh derives all of these; hand-editing them is the single most
# common way this repo's schema drifts from its source of truth. Changing a
# generated file is only legitimate alongside a source change (schema/*.yml,
# state/*.yml, generate-reader.uc, merge-schema.py or generate.sh itself).
# generate.sh also writes docs/ucentral-{schema,state}.html, but those are
# .gitignore'd ('docs/*.html'), so they can never appear in a diff — listing
# them here would be dead weight.
GENERATED=(
  ucentral.schema.json
  ucentral.schema.pretty.json
  ucentral.schema.full.json
  ucentral.state.pretty.json
  schemareader.uc
)

mapfile -t changed_all < <(git diff --name-only --diff-filter=ACMR "$RANGE")

changed_generated=()
for g in "${GENERATED[@]}"; do
  for c in "${changed_all[@]:-}"; do
    [ "$c" = "$g" ] && changed_generated+=("$g")
  done
done

if [ "${#changed_generated[@]}" -gt 0 ]; then
  sources=$(printf '%s\n' "${changed_all[@]}" \
    | grep -E '^(schema/.*\.yml|state/.*\.yml|generate-reader\.uc|merge-schema\.py|generate\.sh)$' || true)
  if [ -z "$sources" ]; then
    err "Generated file(s) changed with no .yml/generator source change: ${changed_generated[*]}. Author in schema/*.yml or state/*.yml and regenerate via ./generate.sh; never hand-edit generated JSON (guidelines §6)."
  else
    echo "Generated files changed alongside source(s): $(echo "$sources" | tr '\n' ' ')— OK."
  fi
fi

# ---------------------------------------------------------------
# 2. ucode files: SPDX on new files, tabs on added lines (§3, §5)
# ---------------------------------------------------------------
# Generated ucode is exempt: it is produced by generate-reader.uc, not authored.
is_generated() {
  local f="$1"
  for g in "${GENERATED[@]}"; do
    [ "$f" = "$g" ] && return 0
  done
  return 1
}

mapfile -t changed_uc < <(git diff --name-only --diff-filter=ACMR "$RANGE" -- '*.uc')

if [ "${#changed_uc[@]}" -eq 0 ]; then
  echo "No ucode files changed; skipping ucode checks."
  [ "$fail" -ne 0 ] && exit 1
  exit 0
fi

# --- SPDX + "use strict" required on NEW .uc files ---
mapfile -t added_uc < <(git diff --name-only --diff-filter=A "$RANGE" -- '*.uc')
for f in "${added_uc[@]:-}"; do
  [ -z "$f" ] && continue
  is_generated "$f" && continue

  # Templates open with '{%', so the identifier may sit on either of the first
  # few lines; check a small window rather than line 1 only.
  #
  # The required form differs by file kind, because a template emits any
  # non-block text verbatim into the rendered UCI:
  #   modules   -> // SPDX-License-Identifier: <license>   (above "use strict";)
  #   templates -> {# SPDX-License-Identifier: <license> #} (a no-output comment)
  # A '//' line above '{%' in a template would land in the generated output.
  if ! head -n3 "$f" | grep -q 'SPDX-License-Identifier:'; then
    case "$f" in
      renderer/templates/*)
        err_at "$f" 1 "$f:1: new ucode template must carry \`{# SPDX-License-Identifier: <package license> #}\` (guidelines §3). Use the \`{# #}\` comment form, not \`//\`: text outside a block tag is emitted verbatim into the rendered UCI."
        ;;
      *)
        err_at "$f" 1 "$f:1: new ucode file must carry \`// SPDX-License-Identifier: <package license>\` above \`\"use strict\";\` (guidelines §3)."
        ;;
    esac
  fi

  # Templates under renderer/templates/ are includes, not modules, so
  # "use strict" does not apply to them.
  case "$f" in
    renderer/templates/*) ;;
    *)
      if ! grep -q '"use strict";' "$f"; then
        warn "$f: new ucode module has no '\"use strict\";' (guidelines §5)."
      fi
      ;;
  esac
done

# --- Space-indentation in ADDED lines (§5: tabs) ---
# Walk the unified diff and flag '+' lines that begin with a space used as
# indentation, excluding block-comment continuations (' *'). The @@ header
# carries the first new-file line of each hunk, so each offender is reported at
# its real location in the file rather than at an offset into the diff text.
for f in "${changed_uc[@]}"; do
  is_generated "$f" && continue

  offenders="$(git diff --unified=0 "$RANGE" -- "$f" | awk '
    /^\+\+\+/    { next }
    /^@@/        { match($0, /\+[0-9]+/)
                   line = substr($0, RSTART + 1, RLENGTH - 1)
                   next }
    /^\+/        { text = substr($0, 2)
                   if (text ~ /^ +[^ *]/) printf "%d\t%s\n", line, text
                   line++ }
  ')"

  [ -z "$offenders" ] && continue

  n=0
  while IFS=$'\t' read -r line text; do
    n=$((n + 1))
    [ "$n" -gt "$MAX_REPORT" ] && continue
    err_at "$f" "$line" "$f:$line: indented with spaces; use tabs (guidelines §5): \`$(trunc "$text")\`"
  done <<< "$offenders"

  if [ "$n" -gt "$MAX_REPORT" ]; then
    err_at "$f" 1 "$f: $((n - MAX_REPORT)) further space-indented line(s) not listed — re-indent the file with tabs (guidelines §5)."
  fi
done

if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "ucode/schema style checks passed on ${#changed_uc[@]} changed ucode file(s)."
