<!-- Source of truth: references/languages/ at the repo root. Edit there, then run scripts/sync-references.sh. -->

# Go

## Running tests

- Run everything with `go test ./...`.
- Run a single test with `go test ./path/to/pkg -run '^TestEmptyCartTotalsZero$'`.
- Add `-race` whenever concurrency is involved, and `-count=1` to bypass the test cache.
- A build error such as "undefined: cart.New" counts as red.

## Pending tests

```go
func TestSingleItemTotalsItsPrice(t *testing.T) {
	t.Skip("pending")
}
```

Use `go test -v` to see skipped tests listed as `SKIP`.

## Unit test shape

Tests live in `cart_test.go` beside `cart.go`. Use `package cart` for white-box tests, or `package cart_test` to test only the exported API (preferred for behaviour tests).

```go
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
```

The `if got != want { t.Errorf(...) }` form is Go's assertion idiom, not test logic. It satisfies the "straight-line body" rule. Use `testify/assert` only if the project already depends on it.

## Seams and test doubles

- The seam is a **small interface defined where it is consumed** (in package `cart`), not next to the implementation: `type PriceCatalog interface { PriceOf(sku string) (int, bool) }`. Go's implicit interfaces make this free.
- Prefer **hand-written fakes**. A map type or a struct with fields is usually a few lines. Use `gomock` or `mockery` only if the project already uses them and you need interaction checks.
- Pass `func() time.Time` or a `Clock` interface rather than calling `time.Now()` inside domain code.
- Compare structs and slices with `github.com/google/go-cmp/cmp` (`cmp.Diff`) for readable failures.

## Parameterised tests

Table-driven subtests are idiomatic. The loop is the parameterisation mechanism, not test logic:

```go
func TestQuantityMultipliesPrice(t *testing.T) {
	tests := []struct {
		name     string
		qty      int
		price    int
		expected int
	}{
		{"single unit", 1, 250, 250},
		{"three units", 3, 250, 750},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Given / When / Then as usual
		})
	}
}
```

## Integration and contract tests

- Keep slow tests out of the default run with a build tag (`//go:build integration`, run with `-tags=integration`), or guard them with `if testing.Short() { t.Skip() }`.
- Managed dependencies: `testcontainers-go`.
- Unmanaged HTTP dependencies: `net/http/httptest.NewServer` as the stub, asserting on the request it receives.
- Async: poll a condition with a deadline (`require.Eventually`, or a small loop over `time.After`). Never sleep for a fixed time.

## Gotchas

- Unordered map iteration makes "many" tests flaky if output order matters. Sort the output or compare as sets.
- Call `t.Helper()` in assertion helpers so failures point at the caller's line.
- Lint and format: `go vet ./...`, `gofmt -l .`, and `staticcheck ./...` if it is available.

## Review smells

- `time.Sleep` in a test, or a real `time.Now()` reached from domain code.
- Table-driven tests whose cases need `if tt.wantErr { … } else { … }` branches that differ in shape. Split them into separate tests.
- Package-level variables swapped out for tests (`var now = time.Now`) instead of an injected dependency.
- `t.Fatal` in a goroutine (it only stops that goroutine). Report back on a channel instead.
- Assertions that print only `got`, so the failure message cannot be read without opening the test.
