#!/usr/bin/env bash
# Go module with acceptance infrastructure in place but only one DSL method
# (Customer.IsRegistered) and one driver method implemented.
set -euo pipefail
printf 'module example.com/shop\n\ngo 1.22\n' > go.mod
mkdir -p acceptance/dsl acceptance/drivers
cat > acceptance/dsl/aliases.go <<'GO'
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
GO
cat > acceptance/dsl/dsl.go <<'GO'
package dsl

// Driver is the protocol driver contract.
type Driver interface {
	RegisterCustomer(name string) error
}

// DSL is what scenarios talk to. Create one per test.
type DSL struct {
	Customer *Customer
}

func New(d Driver) *DSL {
	a := NewAliases()
	return &DSL{Customer: &Customer{d: d, a: a}}
}

type Customer struct {
	d       Driver
	a       *Aliases
	current string
}

func (c *Customer) IsRegistered() error {
	c.current = c.a.Alias("customer")
	return c.d.RegisterCustomer(c.current)
}
GO
cat > acceptance/drivers/http.go <<'GO'
package drivers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"time"

	"example.com/shop/acceptance/dsl"
)

func FromEnv() (dsl.Driver, error) {
	base := os.Getenv("SUT_URL")
	if base == "" {
		base = "http://localhost:8080"
	}
	return &HTTP{base: base, client: &http.Client{Timeout: 5 * time.Second}}, nil
}

type HTTP struct {
	base   string
	client *http.Client
}

func (h *HTTP) RegisterCustomer(name string) error {
	return h.post("/customers", map[string]any{"name": name, "email": name + "@example.test"})
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
GO
