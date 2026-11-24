#!/usr/bin/env bash
# A rate limiter whose Allow is a check-then-act race: the mutex is released between
# reading the count and incrementing it, so concurrent callers can exceed the limit.
set -euo pipefail
printf 'module example.com/api\n\ngo 1.22\n' > go.mod
mkdir -p ratelimit
cat > ratelimit/limiter.go <<'GO'
// Package ratelimit caps requests per key per window.
package ratelimit

import (
	"sync"
	"time"
)

// Limiter allows at most Max requests per key in each Window.
type Limiter struct {
	Max    int
	Window time.Duration

	mu     sync.Mutex
	counts map[string]int
	reset  time.Time
}

// New returns a limiter.
func New(max int, window time.Duration) *Limiter {
	return &Limiter{Max: max, Window: window, counts: map[string]int{}, reset: time.Now().Add(window)}
}

// Allow reports whether a request for key is within the limit, and counts it if so.
func (l *Limiter) Allow(key string) bool {
	l.mu.Lock()
	if time.Now().After(l.reset) {
		l.counts = map[string]int{}
		l.reset = time.Now().Add(l.Window)
	}
	n := l.counts[key]
	l.mu.Unlock()

	if n >= l.Max {
		return false
	}

	l.mu.Lock()
	l.counts[key] = n + 1
	l.mu.Unlock()
	return true
}
GO
