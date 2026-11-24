#!/usr/bin/env bash
# Tests for skills/constraints/scripts/floor-guard.sh.
# Each case builds a throwaway git repo, makes a change on a branch, and checks
# the guard's exit code and the rules it reports.
#
#   scripts/test-floor-guard.sh   exit 1 if any case fails (for CI)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
guard=$root/skills/constraints/scripts/floor-guard.sh
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.com GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.com

passed=0 failed=0
fail() { echo "FAIL $case_name: $1"; echo "$out" | sed 's/^/    /'; failed=$((failed + 1)); }
ok() { passed=$((passed + 1)); }

# new_repo <name>: a repo on main whose files come from the heredoc-fed setup function.
new_repo() {
  case_name=$1
  repo=$work/$1
  mkdir -p "$repo" && cd "$repo" || exit 1
  git init -q -b main
}
commit_base() { git add -A && git commit -qm base && git checkout -qb feature; }
run() { out=$("$guard" "$@" 2>&1); code=$?; }

# expect <exit code> [rule ...]: the guard exits with that code and reports each rule.
expect() {
  local want=$1; shift
  run
  if [ "$code" != "$want" ]; then fail "exit $code, want $want"; return; fi
  for rule in "$@"; do
    if ! grep -q "\[$rule\]" <<< "$out"; then fail "missing [$rule]"; return; fi
  done
  ok
}
# expect_not <rule>: the last run did not report that rule.
expect_not() {
  if grep -q "\[$1\]" <<< "$out"; then fail "unexpected [$1]"; else ok; fi
}

constraints_base() {
  cat > CONSTRAINTS.md <<'MD'
# Constraints

## Floor
- No new suppressions: @ts-ignore, # noqa, //nolint
- No skipped tests: without a reason

## Enforced with numbers
| Dimension | Rule | Checked by | Runs at |
|---|---|---|---|
| Coverage | changed lines ≥ 80% | vitest run --coverage | task end |
| Bundle | main entry <= 200 kB | size-limit | CI |
| Types | 0 errors | tsc --noEmit | task end | block |

## Measured, not yet enforced
| Metric | Today | Direction |
|---|---|---|
| Project coverage | 62.4% | must not fall |

## Exceptions
| ID | Rule | Path | Reason | Owner | Expires |
|---|---|---|---|---|---|
| X1 | no-explicit-any | src/legacy/** | Rewrite in ENG-1 | @a | 2999-01-01 |
| X2 | no-explicit-any | src/old/** | Gone | @a | 2000-01-01 |
MD
}

# --- clean ---------------------------------------------------------------
new_repo clean
echo 'export const a = 1;' > a.ts; commit_base
echo 'export const b = 2;' >> a.ts
expect 0

# --- suppressions across languages --------------------------------------
new_repo suppressions
echo 'x' > a.ts; echo 'x' > a.rs; echo 'x' > a.go; echo 'x' > a.py; commit_base
echo '// @ts-ignore' >> a.ts
echo '#[allow(clippy::unwrap_used)]' >> a.rs
echo 'x := 1 //nolint:errcheck' >> a.go
echo 'import os  # noqa: F401' >> a.py
expect 1 silenced-checker
[ "$(grep -c '\[silenced-checker\]' <<< "$out")" = 4 ] && ok || fail "want 4 silenced-checker findings"

# --- prose is not scanned -----------------------------------------------
new_repo prose
echo '# notes' > NOTES.md; commit_base
echo 'Never add @ts-ignore or a TODO.' >> NOTES.md
expect 0

# --- unfinished work ----------------------------------------------------
new_repo unfinished
echo 'x' > a.py; echo 'x' > a.rs; echo 'x' > a.ts; commit_base
printf 'try:\n    run()\nexcept ValueError:\n    pass\n' >> a.py
echo 'fn f() { todo!() }' >> a.rs
printf 'try { go() } catch (e) {\n}\n' >> a.ts
expect 1 unfinished-work
[ "$(grep -c '\[unfinished-work\]' <<< "$out")" = 3 ] && ok || fail "want 3 unfinished-work findings"

# --- skips and focus ----------------------------------------------------
new_repo skips
mkdir -p src; echo 'x' > src/a.test.ts; echo 'package a' > a_test.go; commit_base
echo 'it.skip("totals", () => {})' >> src/a.test.ts
echo 'describe.only("cart", () => {})' >> src/a.test.ts
echo '	t.Skip("flaky")' >> a_test.go
expect 1 test-made-easier
[ "$(grep -c '\[test-made-easier\]' <<< "$out")" = 3 ] && ok || fail "want 3 test-made-easier findings"

# --- deleted test file --------------------------------------------------
new_repo deleted-test
mkdir tests; echo 'def test_a(): assert 1' > tests/test_a.py; commit_base
git rm -q tests/test_a.py
expect 1 test-deleted

# --- assertions removed vs. rewritten -----------------------------------
new_repo assertions
printf 'expect(total).toBe(3);\nexpect(count).toBe(1);\n' > cart.test.ts; commit_base
printf 'expect(total).toBe(4);\n' > cart.test.ts
expect 1 assertion-removed
new_repo assertion-rewritten
printf 'expect(total).toBe(3);\n' > cart.test.ts; commit_base
printf 'expect(total).toEqual(3);\n' > cart.test.ts
expect 0

# --- untracked files are scanned ----------------------------------------
new_repo untracked
echo 'x' > a.ts; commit_base
echo '// eslint-disable-next-line' > new.ts
expect 1 silenced-checker

# --- CONSTRAINTS.md: loosening is loud, tightening is silent ------------
new_repo loosened
constraints_base; commit_base
sed -i.bak 's/≥ 80%/≥ 70%/; s/<= 200 kB/<= 250 kB/; s/62.4%/60.1%/; s/| block |/| warn |/' CONSTRAINTS.md && rm CONSTRAINTS.md.bak
expect 1 threshold-loosened
[ "$(grep -c '\[threshold-loosened\]' <<< "$out")" = 4 ] && ok || fail "want 4 threshold-loosened findings"

new_repo unknown-direction
constraints_base; commit_base
sed -i.bak 's/| 0 errors |/| 3 errors |/' CONSTRAINTS.md && rm CONSTRAINTS.md.bak
expect 1 threshold-changed

new_repo tightened
constraints_base; commit_base
sed -i.bak 's/≥ 80%/≥ 90%/; s/<= 200 kB/<= 150 kB/; s/62.4%/64.0%/' CONSTRAINTS.md && rm CONSTRAINTS.md.bak
expect 0

new_repo rule-removed
constraints_base; commit_base
sed -i.bak '/^- No skipped tests/d; /^| Bundle/d' CONSTRAINTS.md && rm CONSTRAINTS.md.bak
expect 1 rule-removed
[ "$(grep -c '\[rule-removed\]' <<< "$out")" = 2 ] && ok || fail "want 2 rule-removed findings"

new_repo exceptions
constraints_base; commit_base
echo '| X3 | no-console | src/cli/** | CLI output | @a | 2999-01-01 |' >> CONSTRAINTS.md
sed -i.bak 's/2999-01-01 |$/3000-01-01 |/' CONSTRAINTS.md && rm CONSTRAINTS.md.bak
sed -i.bak '/^| X2 /d' CONSTRAINTS.md && rm CONSTRAINTS.md.bak
expect 1 new-exception exception-changed
expect_not rule-removed

new_repo new-constraints-file
echo 'x' > a.ts; commit_base
constraints_base
expect 0

# --- floor-ok markers ---------------------------------------------------
new_repo floor-ok
constraints_base; echo 'x' > a.ts; commit_base
echo 'const v: any = 1; // eslint-disable-line -- floor-ok: X1' >> a.ts
expect 0
echo 'const w: any = 1; // eslint-disable-line -- floor-ok: X2' >> a.ts
expect 1 silenced-checker
echo 'const z: any = 1; // eslint-disable-line -- floor-ok: X9' >> a.ts
run; [ "$(grep -c '\[silenced-checker\]' <<< "$out")" = 2 ] && ok || fail "expired and unknown IDs must not allow"

# --- base selection -----------------------------------------------------
new_repo explicit-base
echo 'x' > a.ts; commit_base
echo '// @ts-ignore' >> a.ts; git commit -qam one
git tag mid
echo 'y' >> a.ts
run --base mid
[ "$code" = 0 ] && ok || fail "--base mid should only see the uncommitted line"

# --- cannot run ---------------------------------------------------------
case_name=not-a-repo
mkdir -p "$work/plain" && cd "$work/plain" || exit 1
run
[ "$code" = 2 ] && ok || fail "exit $code outside a repo, want 2"
out=$(echo '{}' | "$guard" --hook 2>&1); code=$?
[ "$code" = 1 ] && ok || fail "hook mode exit $code outside a repo, want 1 (non-blocking)"

# --- hook mode ----------------------------------------------------------
new_repo hook
echo 'x' > a.ts; commit_base
echo '// @ts-ignore' >> a.ts
unset CLAUDE_PROJECT_DIR
out=$(echo '{"stop_hook_active": false}' | "$guard" --hook); code=$?
if [ "$code" = 0 ] && grep -q '"decision":"block"' <<< "$out"; then ok; else fail "first stop should block"; fi
if command -v python3 >/dev/null; then
  python3 -c 'import json,sys; json.loads(sys.stdin.read())' <<< "$out" && ok || fail "hook output is not valid JSON"
fi
out=$(echo '{"stop_hook_active": false}' | "$guard" --hook)
[ -z "$out" ] && ok || fail "an already-reported finding should not block again"
echo '// @ts-nocheck' >> a.ts
out=$(echo '{"stop_hook_active": true}' | "$guard" --hook)
[ -z "$out" ] && ok || fail "stop_hook_active should never block"
out=$(echo '{"stop_hook_active": false}' | "$guard" --hook)
grep -q 'ts-nocheck' <<< "$out" && ! grep -q 'ts-ignore' <<< "$out" && ok || fail "only the new finding should block"

echo "floor-guard tests: $passed passed, $failed failed"
[ "$failed" = 0 ]
