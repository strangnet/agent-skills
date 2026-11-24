#!/usr/bin/env bash
# A tiny committed Go package, so the session's change shows up in `git status`.
set -euo pipefail
printf 'module example.com/greet\n\ngo 1.22\n' > go.mod
mkdir -p greet
cat > greet/greet.go <<'GO'
// Package greet builds greetings.
package greet

// Hello returns a plain greeting.
func Hello(name string) string {
	return "Hello, " + name
}
GO
cat > greet/greet_test.go <<'GO'
package greet

import "testing"

func TestHello(t *testing.T) {
	if got := Hello("Ada"); got != "Hello, Ada" {
		t.Fatalf("Hello(\"Ada\") = %q, want %q", got, "Hello, Ada")
	}
}
GO
git init -q
git add -A
git -c user.name=eval -c user.email=eval@example.com commit -qm "initial"
