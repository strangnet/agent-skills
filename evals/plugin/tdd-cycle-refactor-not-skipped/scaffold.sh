#!/usr/bin/env bash
# Go module where green has just finished: one passing test, a minimal implementation, one pending test.
set -euo pipefail
printf 'module example.com/shop\n\ngo 1.22\n' > go.mod
mkdir -p cart
cat > cart/cart.go <<'GO'
// Package cart computes shopping cart totals.
package cart

type PriceCatalog interface {
	PriceOf(sku string) (int, bool)
}

type Cart struct {
	c PriceCatalog
}

func New(c PriceCatalog) *Cart {
	return &Cart{c: c}
}

func (x *Cart) Total() int {
	return 0
}
GO
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
