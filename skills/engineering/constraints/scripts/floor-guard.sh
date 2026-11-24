#!/usr/bin/env bash
# floor-guard: diff-scoped check that a change does not lower the project's bar.
#
# Detects the moves an agent makes to get to green cheaply:
#   silenced-checker   a new suppression (@ts-ignore, # noqa, //nolint, #[allow(...)], ...)
#   unfinished-work    a new stub, empty catch/except, todo!(), TODO/FIXME
#   test-made-easier   a new skip/only/ignore marker on a test
#   test-deleted       a test file removed
#   assertion-removed  a test file that stayed lost more assertions than it gained
#   rule-removed       a rule disappeared from CONSTRAINTS.md
#   threshold-loosened a CONSTRAINTS.md number moved the wrong way (>= down, <= up),
#                      or a rule's mode went from block to something else
#   threshold-changed  a CONSTRAINTS.md number with no comparator changed
#   new-exception      a row added to the CONSTRAINTS.md exceptions table
#   exception-changed  an existing exception row edited (path widened, expiry pushed)
#
# The diff runs from the merge base with the base branch to the working tree,
# including staged, unstaged and untracked files. Tightening is silent.
#
# A finding on a line that carries `floor-ok: X<n>`, where X<n> is an unexpired
# row in the CONSTRAINTS.md exceptions table, is allowed.
#
# Usage:
#   floor-guard.sh [--base <ref>]   report; exit 0 clean, 1 findings, 2 could not run
#   floor-guard.sh --hook           Claude Code Stop hook: blocks once per new finding
#
# Base ref: --base, else $FLOOR_GUARD_BASE, else origin/HEAD, origin/main,
# origin/master, main, master (the first that exists).
#
# Needs only bash, git and a POSIX awk.
set -uo pipefail

mode=report
base=${FLOOR_GUARD_BASE:-}
while [ $# -gt 0 ]; do
  case $1 in
    --hook) mode=hook ;;
    --base) base=${2:-}; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "floor-guard: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

hook_input=
if [ "$mode" = hook ]; then
  hook_input=$(cat || true)
  [ -n "${CLAUDE_PROJECT_DIR:-}" ] && cd "$CLAUDE_PROJECT_DIR"
fi

# In hook mode a guard that can't run must not block (exit 2 would), so it
# exits 1, a non-blocking error the user sees.
bail() {
  echo "floor-guard: $1" >&2
  if [ "$mode" = hook ]; then exit 1; else exit 2; fi
}

top=$(git rev-parse --show-toplevel 2>/dev/null) || bail "not inside a git work tree"
cd "$top" || bail "cannot enter $top"

if [ -z "$base" ]; then
  base=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)
  if [ -z "$base" ]; then
    for candidate in origin/main origin/master main master; do
      if git rev-parse -q --verify "$candidate^{commit}" >/dev/null 2>&1; then
        base=$candidate
        break
      fi
    done
  fi
fi
[ -n "$base" ] || bail "no base branch found; pass --base <ref>"

merge_base=$(git merge-base "$base" HEAD 2>/dev/null) || bail "no merge base between $base and HEAD"

diff=$(git -c core.quotePath=false diff --unified=0 --no-color --no-ext-diff -M "$merge_base" --) \
  || bail "could not diff against $merge_base"

untracked=$(git -c core.quotePath=false ls-files --others --exclude-standard) \
  || bail "could not list untracked files"
if [ -n "$untracked" ]; then
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    # --no-index exits 1 when the files differ, which is always the case here.
    d=$(git diff --no-index --unified=0 --no-color --no-ext-diff /dev/null "$f")
    [ $? -le 1 ] || bail "could not diff untracked file $f"
    diff=$diff$'\n'$d
  done <<< "$untracked"
fi

# Unexpired exception IDs that a `floor-ok:` marker may cite.
today=$(date +%Y-%m-%d)
valid_exceptions=
if [ -f CONSTRAINTS.md ]; then
  valid_exceptions=$(awk -v today="$today" '
    /^\|[[:space:]]*X[0-9]+[[:space:]]*\|/ {
      id = $0; sub(/^\|[[:space:]]*/, "", id); sub(/[[:space:]]*\|.*/, "", id)
      expiry = ""; line = $0
      while (match(line, /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/)) {
        expiry = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
      }
      if (expiry != "" && expiry >= today) printf "%s ", id
    }' CONSTRAINTS.md)
fi

findings=$(printf '%s\n' "$diff" | awk -v valid=" $valid_exceptions" '
function strip_path(p) {
  sub(/^"/, "", p); sub(/"$/, "", p); sub(/^[ab]\//, "", p); return p
}
function is_test(f) {
  return f ~ /(^|\/)(tests?|__tests__|spec|specs)\// || f ~ /\.(test|spec)\.[A-Za-z0-9]+$/ \
      || f ~ /_test\.(go|py)$/ || f ~ /(^|\/)test_[^\/]*\.py$/ || f ~ /_spec\.rb$/
}
function is_constraints(f) { return f ~ /(^|\/)CONSTRAINTS\.md$/ }
function is_prose(f) {
  return f ~ /\.(md|markdown|txt|rst|adoc)$/ || f ~ /(^|\/)floor-guard[^\/]*$/ \
      || f ~ /(^|\/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|poetry\.lock|uv\.lock)$/
}
function emit(rule, f, ln, text) {
  gsub(/\t/, " ", text); sub(/^[[:space:]]+/, "", text)
  if (length(text) > 120) text = substr(text, 1, 117) "..."
  printf "%s\t%s\t%s\n", rule, (ln > 0 ? f ":" ln : f), text
}
function allowed(text,   id) {
  if (!match(text, /floor-ok:[[:space:]]*X[0-9]+/)) return 0
  id = substr(text, RSTART, RLENGTH); sub(/floor-ok:[[:space:]]*/, "", id)
  return index(valid, " " id " ") > 0
}
function is_assertion(t) {
  return t ~ /(^|[^A-Za-z_])(expect|assert[A-Za-z_]*|should)[^A-Za-z_]/ \
      || t ~ /(assert|assert_eq|assert_ne|debug_assert)!/ \
      || t ~ /(^|[^A-Za-z_])(require|assert)\.[A-Z]/ \
      || t ~ /(^|[^A-Za-z_])t\.(Error|Errorf|Fatal|Fatalf|Fail|FailNow)\(/
}
# CONSTRAINTS.md rules: a bullet keyed by its text before the first colon, or a
# table row keyed by its first cell. Separator rows and prose are not rules.
function rule_key(t,   k) {
  if (t ~ /^\|[[:space:]:-]*\|/ && t !~ /[A-Za-z0-9]/) return ""
  if (t ~ /^\|/) { k = t; sub(/^\|[[:space:]]*/, "", k); sub(/[[:space:]]*\|.*/, "", k); return k }
  if (t ~ /^[-*] /) { k = substr(t, 3); sub(/:.*/, "", k); sub(/[[:space:]]+$/, "", k); return k }
  return ""
}
function is_exception_row(t) { return t ~ /^\|[[:space:]]*X[0-9]+[[:space:]]*\|/ }
# Writes "dir:value" tokens to the global list T[1..n]; returns n. A number is a
# minimum after >= / ≥ / > or in a row that says "must not fall", a maximum after
# <= / ≤ / < or in a row that says "must not grow", and directionless otherwise.
function thresholds(t,   n, rest, dir, num, rowdir, pre) {
  n = 0; rest = t; rowdir = ""
  if (t ~ /must not (fall|drop|decrease)/) rowdir = "min"
  if (t ~ /must not (grow|rise|increase|exceed)/) rowdir = "max"
  while (match(rest, /[0-9]+(\.[0-9]+)?/)) {
    num = substr(rest, RSTART, RLENGTH)
    pre = substr(rest, 1, RSTART - 1)
    rest = substr(rest, RSTART + RLENGTH)
    if (pre ~ /[0-9-]$/ || rest ~ /^-[0-9]/) continue   # part of a date or ID
    dir = rowdir
    if (pre ~ /(>=|≥|>)[[:space:]]*$/) dir = "min"
    else if (pre ~ /(<=|≤|<)[[:space:]]*$/) dir = "max"
    T[++n] = (dir == "" ? "any" : dir) ":" num
  }
  return n
}
function compare_rule(old, new, f, ln,   i, j, no, nn, d, ov, nv, OLD, NEW, oc, nc, cnt) {
  if (old ~ /\|[[:space:]]*block[[:space:]]*\|/ && new !~ /\|[[:space:]]*block[[:space:]]*\|/) {
    emit("threshold-loosened", f, ln, old " -> " new); return
  }
  no = thresholds(old); for (i = 1; i <= no; i++) OLD[i] = T[i]
  nn = thresholds(new); for (i = 1; i <= nn; i++) NEW[i] = T[i]
  split("min max any", dirs, " ")
  for (d = 1; d <= 3; d++) {
    oc = 0; nc = 0
    for (i = 1; i <= no; i++) if (OLD[i] ~ "^" dirs[d] ":") { oc++; ov[oc] = substr(OLD[i], 5) + 0 }
    for (i = 1; i <= nn; i++) if (NEW[i] ~ "^" dirs[d] ":") { nc++; nv[nc] = substr(NEW[i], 5) + 0 }
    for (j = 1; j <= oc; j++) {
      if (j > nc) { emit("threshold-loosened", f, ln, old " -> " new); return }
      if (dirs[d] == "min" && nv[j] < ov[j]) { emit("threshold-loosened", f, ln, old " -> " new); return }
      if (dirs[d] == "max" && nv[j] > ov[j]) { emit("threshold-loosened", f, ln, old " -> " new); return }
      if (dirs[d] == "any" && nv[j] != ov[j]) { emit("threshold-changed", f, ln, old " -> " new); return }
    }
  }
}

/^diff / { in_header = 1; file = ""; old_file = ""; prev_add = ""; next }
in_header && /^--- / { old_file = strip_path(substr($0, 5)); next }
in_header && /^\+\+\+ / {
  new_file = strip_path(substr($0, 5))
  if (new_file == "/dev/null") { file = old_file; deleted[file] = 1 } else file = new_file
  next
}
/^@@/ {
  in_header = 0; prev_add = ""
  split($0, h, " ")
  o = h[2]; sub(/^-/, "", o); split(o, oa, ","); old_ln = oa[1] + 0
  n = h[3]; sub(/^\+/, "", n); split(n, na, ","); new_ln = na[1] + 0
  next
}
in_header { next }
/^\+/ {
  text = substr($0, 2); ln = new_ln++
  if (is_constraints(file)) {
    k = rule_key(text)
    if (k != "") { added_rule[k] = text; added_ln[k] = ln }
    # A new CONSTRAINTS.md sets the bar; only exceptions added to an existing one are news.
    if (is_exception_row(text) && old_file != "/dev/null") new_exception[k] = file ":" ln "\t" text
  } else if (!is_prose(file) && !allowed(text)) {
    if (text ~ /@ts-(ignore|nocheck|expect-error)|eslint-disable|biome-ignore|oxlint-disable|(istanbul|c8|v8) ignore|#[[:space:]]*(noqa|type:[[:space:]]*ignore|pyright:[[:space:]]*ignore|pragma:[[:space:]]*no cover|nosec)|pylint:[[:space:]]*disable|\/\/[[:space:]]*nolint|#!?\[(allow|expect)\(|coverage\(off\)|tarpaulin_include|nosemgrep|gitleaks:allow|Stryker disable|mutmut:[[:space:]]*no mutate/)
      emit("silenced-checker", file, ln, text)
    if (text ~ /(todo|unimplemented)!\(|panic\("([Nn]ot implemented|TODO|todo)|raise NotImplementedError|throw new [A-Za-z]*Error\(["\047`][Nn]ot implemented|catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}|except[^:]*:[[:space:]]*pass[[:space:]]*$|(^|[^A-Za-z])(TODO|FIXME|XXX)([^A-Za-z]|$)/)
      emit("unfinished-work", file, ln, text)
    else if (text ~ /^[[:space:]]*pass[[:space:]]*$/ && prev_add ~ /except[^:]*:[[:space:]]*$/)
      emit("unfinished-work", file, ln - 1, prev_add " " text)
    else if (text ~ /^[[:space:]]*\}/ && prev_add ~ /catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*$/)
      emit("unfinished-work", file, ln - 1, prev_add " " text)
    if (text ~ /\.(skip|only|todo)[(.]|(^|[^A-Za-z_.])(xit|xdescribe|xtest|fit|fdescribe)\(|@pytest\.mark\.(skip|skipif|xfail)|@unittest\.skip|unittest\.skip|t\.Skip(Now|f)?\(|#\[ignore/)
      emit("test-made-easier", file, ln, text)
  }
  if (is_test(file) && is_assertion(text)) asserts_added[file]++
  prev_add = text
  next
}
/^-/ {
  text = substr($0, 2); ln = old_ln++
  if (is_constraints(file)) {
    k = rule_key(text)
    if (k != "") { removed_rule[k] = text; removed_ln[k] = ln; removed_order[++n_removed] = k }
  }
  if (is_test(file) && is_assertion(text)) asserts_removed[file]++
  prev_add = ""
  next
}
END {
  for (f in deleted) if (is_test(f)) emit("test-deleted", f, 0, "test file deleted")
  for (f in asserts_removed)
    if (!(f in deleted) && asserts_removed[f] > asserts_added[f] + 0)
      emit("assertion-removed", f, 0, (asserts_removed[f] - asserts_added[f]) " assertion(s) fewer than before")
  for (i = 1; i <= n_removed; i++) {
    k = removed_order[i]; old = removed_rule[k]
    if (!(k in added_rule)) {
      if (!is_exception_row(old)) emit("rule-removed", "CONSTRAINTS.md", removed_ln[k], old)
      continue
    }
    if (is_exception_row(old)) {
      if (added_rule[k] != old) emit("exception-changed", "CONSTRAINTS.md", added_ln[k], old " -> " added_rule[k])
      delete new_exception[k]
      continue
    }
    compare_rule(old, added_rule[k], "CONSTRAINTS.md", added_ln[k])
  }
  for (k in new_exception) {
    split(new_exception[k], parts, "\t"); split(parts[1], loc, ":")
    emit("new-exception", loc[1], loc[2], parts[2])
  }
}')

if [ "$mode" = report ]; then
  if [ -z "$findings" ]; then
    echo "floor-guard: clean (against $base)"
    exit 0
  fi
  count=$(printf '%s\n' "$findings" | wc -l | tr -d ' ')
  echo "floor-guard: $count finding(s) against $base:" >&2
  printf '%s\n' "$findings" | awk -F '\t' '{ printf "  [%s] %s  %s\n", $1, $2, $3 }' >&2
  echo "Each lowers the bar. Fix the code, or record an exception in CONSTRAINTS.md and cite it with floor-ok: X<n>." >&2
  exit 1
fi

# Hook mode: block once for findings not reported before in this work tree, so an
# approved finding (a pending test, an agreed deletion) never blocks twice.
[ -z "$findings" ] && exit 0
if printf '%s' "$hook_input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi
state=$(git rev-parse --git-path floor-guard-reported 2>/dev/null) || exit 0
touch "$state" 2>/dev/null || exit 0
new=$(printf '%s\n' "$findings" | grep -vxF -f "$state" || true)
[ -z "$new" ] && exit 0
printf '%s\n' "$new" >> "$state"

printf '%s\n' "$new" | awk -F '\t' '
function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); gsub(/\t/, " ", s); return s }
{ body = body "\\n- [" esc($1) "] " esc($2) "  " esc($3) }
END {
  reason = "floor-guard: this change lowers the bar set in CONSTRAINTS.md:" body \
    "\\n\\nFix each one. If a finding is intended (a pending test in a TDD test list, a deletion the user asked for), say so to the user and stop; do not edit CONSTRAINTS.md to make this pass."
  printf "{\"decision\":\"block\",\"reason\":\"%s\"}\n", reason
}'
exit 0
