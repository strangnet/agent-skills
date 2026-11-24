# Go: acceptance layers

All four languages implement the same running example: a shop gives 10% off orders of 100.00 or more.

```gherkin
Feature: Checkout discounts

  Scenario: Orders at the threshold get ten percent off
    Given a registered customer
    And a product "Desk lamp" priced at 100.00
    When the customer buys "Desk lamp"
    Then the customer is charged 90.00
```

The driver talks HTTP to a running shop (`POST /customers`, `POST /products`, `POST /orders`, `GET /customers/{name}/orders/latest`). Treat the code as a pattern: rename the domain to match the project and keep the layer boundaries.

## Layout and dependencies

```text
acceptance/
  dsl/aliases.go          alias helper
  dsl/dsl.go              driver interface, DSL root, domain areas
  drivers/http.go         HTTP driver + factory
  checkout_test.go        scenario without Gherkin
  features/checkout.feature
  features_test.go        scenario with Gherkin (godog)
```

Stdlib only, plus `github.com/cucumber/godog` if Gherkin is used.

**Failure convention:** driver methods return an `error`, and the DSL passes it up. Go's idiom is to return an error rather than panic. Tests turn the error into a failure with a `must` helper, and godog steps return it directly.

## Alias helper

`acceptance/dsl/aliases.go`

```go
package dsl

import (
	"fmt"
	"sync/atomic"
	"time"
)

var (
	runID = time.Now().UnixNano() % 1_000_000
	seq   atomic.Int64
)

// Aliases maps the plain names a scenario uses to names unique to this test.
// The same name maps to the same alias for the whole test.
type Aliases struct{ m map[string]string }

func NewAliases() *Aliases { return &Aliases{m: map[string]string{}} }

func (a *Aliases) Alias(name string) string {
	if v, ok := a.m[name]; ok {
		return v
	}
	v := fmt.Sprintf("%s-%d-%d", name, runID, seq.Add(1))
	a.m[name] = v
	return v
}
```

## DSL and driver interface

The interface lives with the DSL, its consumer, as Go convention prefers.

`acceptance/dsl/dsl.go`

```go
package dsl

import "fmt"

// Driver is the protocol driver contract. Every method returns an error when
// the system under test does not behave as expected.
type Driver interface {
	RegisterCustomer(name string) error
	CreateProduct(name string, priceCents int) error
	PlaceOrder(customer, product string) error
	ConfirmLastCharge(customer string, amountCents int) error
}

// DSL is what scenarios talk to. Create one per test.
type DSL struct {
	Customer *Customer
	Catalog  *Catalog
}

func New(d Driver) *DSL {
	a := NewAliases()
	return &DSL{Customer: &Customer{d: d, a: a}, Catalog: &Catalog{d: d, a: a}}
}

type Customer struct {
	d       Driver
	a       *Aliases
	current string // bridging state: the customer later steps refer to
}

func (c *Customer) IsRegistered() error {
	c.current = c.a.Alias("customer")
	return c.d.RegisterCustomer(c.current)
}

func (c *Customer) Buys(product string) error {
	return c.d.PlaceOrder(c.current, c.a.Alias(product))
}

func (c *Customer) ConfirmCharged(amount string) error {
	cents, err := toCents(amount)
	if err != nil {
		return err
	}
	return c.d.ConfirmLastCharge(c.current, cents)
}

type Catalog struct {
	d Driver
	a *Aliases
}

func (c *Catalog) HasProduct(name, price string) error {
	cents, err := toCents(price)
	if err != nil {
		return err
	}
	return c.d.CreateProduct(c.a.Alias(name), cents)
}

func toCents(amount string) (int, error) {
	var whole, frac int
	if _, err := fmt.Sscanf(amount, "%d.%02d", &whole, &frac); err != nil {
		return 0, fmt.Errorf("amount %q: %w", amount, err)
	}
	return whole*100 + frac, nil
}
```

## HTTP driver and factory

`acceptance/drivers/http.go`

```go
package drivers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"time"

	"example.com/shop/acceptance/dsl"
)

// FromEnv picks the driver for this run: ACCEPTANCE_DRIVER=http (default).
func FromEnv() (dsl.Driver, error) {
	switch v := os.Getenv("ACCEPTANCE_DRIVER"); v {
	case "", "http":
		base := os.Getenv("SUT_URL")
		if base == "" {
			base = "http://localhost:8080"
		}
		return &HTTP{base: base, client: &http.Client{Timeout: 5 * time.Second}}, nil
	default:
		return nil, fmt.Errorf("unknown ACCEPTANCE_DRIVER %q", v)
	}
}

type HTTP struct {
	base   string
	client *http.Client
}

func (h *HTTP) RegisterCustomer(name string) error {
	return h.post("/customers", map[string]any{"name": name, "email": name + "@example.test"})
}

func (h *HTTP) CreateProduct(name string, priceCents int) error {
	return h.post("/products", map[string]any{"name": name, "price_cents": priceCents})
}

func (h *HTTP) PlaceOrder(customer, product string) error {
	return h.post("/orders", map[string]any{"customer": customer, "product": product})
}

// ConfirmLastCharge asks the system, which is the single source of truth.
// Orders settle asynchronously, so poll with a deadline.
func (h *HTTP) ConfirmLastCharge(customer string, amountCents int) error {
	return eventually(5*time.Second, func() error {
		var got struct {
			ChargedCents int `json:"charged_cents"`
		}
		if err := h.get("/customers/"+url.PathEscape(customer)+"/orders/latest", &got); err != nil {
			return err
		}
		if got.ChargedCents != amountCents {
			return fmt.Errorf("%s was charged %d cents, want %d", customer, got.ChargedCents, amountCents)
		}
		return nil
	})
}

func (h *HTTP) post(path string, body any) error {
	b, err := json.Marshal(body)
	if err != nil {
		return err
	}
	resp, err := h.client.Post(h.base+path, "application/json", bytes.NewReader(b))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		return fmt.Errorf("POST %s: %s", path, resp.Status)
	}
	return nil
}

func (h *HTTP) get(path string, out any) error {
	resp, err := h.client.Get(h.base + path)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("GET %s: %s", path, resp.Status)
	}
	return json.NewDecoder(resp.Body).Decode(out)
}

func eventually(timeout time.Duration, check func() error) error {
	deadline := time.Now().Add(timeout)
	for {
		err := check()
		if err == nil || time.Now().After(deadline) {
			return err
		}
		time.Sleep(100 * time.Millisecond)
	}
}
```

## Scenario without Gherkin

`acceptance/checkout_test.go`

```go
package acceptance_test

import (
	"testing"

	"example.com/shop/acceptance/drivers"
	"example.com/shop/acceptance/dsl"
)

func TestOrdersAtTheThresholdGetTenPercentOff(t *testing.T) {
	t.Parallel()
	d := newDSL(t)

	// Given
	must(t, d.Customer.IsRegistered())
	must(t, d.Catalog.HasProduct("Desk lamp", "100.00"))

	// When
	must(t, d.Customer.Buys("Desk lamp"))

	// Then
	must(t, d.Customer.ConfirmCharged("90.00"))
}

func newDSL(t *testing.T) *dsl.DSL {
	t.Helper()
	drv, err := drivers.FromEnv()
	must(t, err)
	return dsl.New(drv)
}

func must(t *testing.T, err error) {
	t.Helper()
	if err != nil {
		t.Fatal(err)
	}
}
```

## Scenario with Gherkin (godog)

`acceptance/features_test.go`

```go
package acceptance_test

import (
	"context"
	"testing"

	"github.com/cucumber/godog"

	"example.com/shop/acceptance/drivers"
	"example.com/shop/acceptance/dsl"
)

func TestFeatures(t *testing.T) {
	suite := godog.TestSuite{
		ScenarioInitializer: initializeScenario,
		Options:             &godog.Options{Format: "pretty", Paths: []string{"features"}, TestingT: t},
	}
	if suite.Run() != 0 {
		t.Fatal("feature tests failed")
	}
}

func initializeScenario(sc *godog.ScenarioContext) {
	var d *dsl.DSL
	sc.Before(func(ctx context.Context, _ *godog.Scenario) (context.Context, error) {
		drv, err := drivers.FromEnv()
		d = dsl.New(drv)
		return ctx, err
	})
	sc.Step(`^a registered customer$`, func() error { return d.Customer.IsRegistered() })
	sc.Step(`^a product "([^"]*)" priced at (\d+\.\d{2})$`, func(name, price string) error {
		return d.Catalog.HasProduct(name, price)
	})
	sc.Step(`^the customer buys "([^"]*)"$`, func(name string) error { return d.Customer.Buys(name) })
	sc.Step(`^the customer is charged (\d+\.\d{2})$`, func(amount string) error {
		return d.Customer.ConfirmCharged(amount)
	})
}
```

## Running

- `SUT_URL=http://localhost:8080 go test ./acceptance/...`
- Keep acceptance tests out of the default unit run with a build tag (`//go:build acceptance`, run with `-tags=acceptance`) or a separate CI job.
- `t.Parallel()` is safe because every test works in its own aliased partition.
