#!/usr/bin/env bash
# Go cart with deliberately weak tests. Planted problems:
#   - imprecise assertion and method-name test name (C1, C5)
#   - time.Sleep in a unit test (A4)
#   - package-level cart shared and mutated across tests (A3)
#   - discount threshold (>= 10000) only tested far above the boundary, so `>=` -> `>` survives (D2, D3)
#   - a commented-out test (D4)
set -euo pipefail
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

// Cart holds items.
type Cart struct {
	items []Item
}

// Add appends an item to the cart.
func (c *Cart) Add(it Item) {
	c.items = append(c.items, it)
}

// Total sums the cart in cents, applying a 10% discount at 10000 cents or more.
func (c *Cart) Total() int {
	sum := 0
	for _, it := range c.items {
		sum += it.Price * it.Qty
	}
	if sum >= 10000 {
		sum = sum * 90 / 100
	}
	return sum
}
GO
cat > cart/cart_test.go <<'GO'
package cart

import (
	"testing"
	"time"
)

var shared = &Cart{}

func TestTotal1(t *testing.T) {
	shared.Add(Item{SKU: "a", Price: 250, Qty: 2})
	if shared.Total() <= 0 {
		t.Error("bad total")
	}
}

func TestDiscount(t *testing.T) {
	shared.Add(Item{SKU: "b", Price: 20000, Qty: 1})
	time.Sleep(10 * time.Millisecond)
	if shared.Total() != 18450 {
		t.Errorf("got %d", shared.Total())
	}
}

// func TestEmpty(t *testing.T) {
// 	c := &Cart{}
// 	if c.Total() != 0 {
// 		t.Fail()
// 	}
// }
GO
