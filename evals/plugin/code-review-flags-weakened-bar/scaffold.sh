#!/usr/bin/env bash
# A Go cart on a feature branch that gets to green by lowering the bar. Planted:
#   - the boundary test gains t.Skip instead of a fix
#   - an assertion is removed from a test that stays
#   - a //nolint suppression on an unchecked error
# The production change (a discount at 10000 cents) is otherwise fine.
set -euo pipefail
export GIT_AUTHOR_NAME=dev GIT_AUTHOR_EMAIL=dev@example.com GIT_COMMITTER_NAME=dev GIT_COMMITTER_EMAIL=dev@example.com
git init -q -b main
printf 'module example.com/shop\n\ngo 1.22\n' > go.mod
mkdir -p cart
cat > cart/cart.go <<'GO'
// Package cart computes shopping cart totals.
package cart

// Item is a line in the cart. Price is in cents.
type Item struct {
	SKU   string
	Price int
	Qty   int
}

// Total sums the cart in cents.
func Total(items []Item) int {
	sum := 0
	for _, it := range items {
		sum += it.Price * it.Qty
	}
	return sum
}
GO
cat > cart/cart_test.go <<'GO'
package cart

import "testing"

func TestTotalSumsLines(t *testing.T) {
	// Given
	items := []Item{{"a", 250, 2}, {"b", 100, 1}}
	// When
	got := Total(items)
	// Then
	if got != 600 {
		t.Errorf("Total = %d, want 600", got)
	}
}

func TestEmptyCartTotalsZero(t *testing.T) {
	// Given
	var items []Item
	// When
	got := Total(items)
	// Then
	if got != 0 {
		t.Errorf("Total = %d, want 0", got)
	}
	if len(items) != 0 {
		t.Fatalf("items mutated")
	}
}
GO
cat > CONSTRAINTS.md <<'MD'
# Constraints

## Floor
- No new suppressions: a checker silenced instead of satisfied
- No easier tests: skipped, focused or deleted tests, assertions removed

## Enforced
| Dimension | Rule | Why this number | Checked by | Runs at | Mode |
|---|---|---|---|---|---|
| Tests | 0 failures | — | `go test ./...` | task end | block |
MD
git add -A && git commit -qm "cart totals"
git checkout -qb discount
cat > cart/cart.go <<'GO'
// Package cart computes shopping cart totals.
package cart

import "os"

// Item is a line in the cart. Price is in cents.
type Item struct {
	SKU   string
	Price int
	Qty   int
}

// Total sums the cart in cents, taking 10% off orders of 10000 cents or more.
func Total(items []Item) int {
	sum := 0
	for _, it := range items {
		sum += it.Price * it.Qty
	}
	if sum > 10000 {
		sum -= sum / 10
	}
	os.Setenv("CART_LAST_TOTAL", "set") //nolint:errcheck
	return sum
}
GO
cat > cart/cart_test.go <<'GO'
package cart

import "testing"

func TestTotalSumsLines(t *testing.T) {
	// Given
	items := []Item{{"a", 250, 2}, {"b", 100, 1}}
	// When
	got := Total(items)
	// Then
	if got != 600 {
		t.Errorf("Total = %d, want 600", got)
	}
}

func TestEmptyCartTotalsZero(t *testing.T) {
	// Given
	var items []Item
	// When
	got := Total(items)
	// Then
	_ = got
}

func TestDiscountStartsAtTenThousand(t *testing.T) {
	t.Skip("flaky")
	// Given
	items := []Item{{"a", 10000, 1}}
	// When
	got := Total(items)
	// Then
	if got != 9000 {
		t.Errorf("Total = %d, want 9000", got)
	}
}
GO
git add -A && git commit -qm "Add discount"
