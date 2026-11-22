#!/usr/bin/env bash
# Go module with one reviewed failing test (cart.New does not exist yet) and one pending test.
set -euo pipefail
printf 'module example.com/shop\n\ngo 1.22\n' > go.mod
mkdir -p cart
printf '// Package cart computes shopping cart totals.\npackage cart\n' > cart/doc.go
cat > cart/cart_test.go <<'GO'
package cart_test

import (
	"testing"

	"example.com/shop/cart"
)

type fakeCatalog map[string]int

func (f fakeCatalog) PriceOf(sku string) (int, bool) {
	p, ok := f[sku]
	return p, ok
}

func TestEmptyCartTotalsZero(t *testing.T) {
	// Given
	c := cart.New(fakeCatalog{})

	// When
	total := c.Total()

	// Then
	if total != 0 {
		t.Errorf("Total() = %d, want 0", total)
	}
}

func TestSingleItemTotalsItsPrice(t *testing.T) {
	t.Skip("pending")
}
GO
