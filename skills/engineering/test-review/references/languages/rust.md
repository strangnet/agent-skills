<!-- Source of truth: references/languages/ at the repo root. Edit there, then run scripts/sync-references.sh. -->

# Rust

## Running tests

- Use `cargo nextest run` if `nextest` is configured, otherwise `cargo test`.
- Run a single test with `cargo test <name_substring>`.
- In a workspace, scope to one crate with `-p <crate>`.
- A compile error counts as red. In Rust, the first failure is usually "cannot find type `Cart`".

## Pending tests

```rust
#[test]
#[ignore = "pending"]
fn single_item_totals_its_price() {}
```

Run pending tests with `cargo test -- --ignored`. Prefer `#[ignore]` over a `todo!()` body, which shows up as a failure rather than as pending.

## Unit test shape

Unit tests live in a `#[cfg(test)] mod tests` block next to the code they test. Example: red for the first ZOMBIES case.

```rust
#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;

    struct FakeCatalog(HashMap<&'static str, u64>);

    impl PriceCatalog for FakeCatalog {
        fn price_of(&self, sku: &str) -> Option<u64> {
            self.0.get(sku).copied()
        }
    }

    #[test]
    fn empty_cart_totals_zero() {
        // Given
        let catalog = FakeCatalog(HashMap::new());
        let cart = Cart::new(&catalog);

        // When
        let total = cart.total();

        // Then
        assert_eq!(total, 0);
    }
}
```

`PriceCatalog` and `Cart` do not exist yet. The compile error is the red, and green creates them.

## Seams and test doubles

- The seam is a **trait**. Production code takes it as a generic (`Cart<'a, C: PriceCatalog>`) or as `&dyn PriceCatalog` / `Box<dyn PriceCatalog>`. Prefer generics unless the type must be stored heterogeneously.
- Prefer **hand-written fakes** like `FakeCatalog` above. They are short, they type-check against the trait, and they read clearly in the test.
- Reach for `mockall` (`#[automock]`) only when you need to verify interactions (that a call was made, with what arguments) and a fake would be clumsy.
- Hide the clock and randomness behind traits too. Calling `SystemTime::now()` directly is a hidden dependency.

## Parameterised tests

With `rstest`:

```rust
#[rstest]
#[case(1, 250, 250)]
#[case(3, 250, 750)]
fn quantity_multiplies_price(#[case] qty: u32, #[case] price: u64, #[case] expected: u64) {
    // Given / When / Then as usual
}
```

Without the crate, put several focused `#[test]` functions side by side rather than a loop inside one test.

## Integration and contract tests

- Integration tests go in `tests/*.rs`. Each file compiles as its own crate and sees only the public API.
- Managed dependencies: the `testcontainers` crate (Postgres, Redis and so on).
- Unmanaged HTTP dependencies: `wiremock` for stub servers that assert on the request shape.
- Async: `#[tokio::test]`. When waiting on a condition, wrap it in `tokio::time::timeout` rather than sleeping.

## Gotchas

- `assert_eq!` failure output needs `Debug` on both sides. Derive it on domain types early.
- Handle money in integer minor units (`u64` cents) or with `rust_decimal`, never `f64`.
- Lint and format: `cargo clippy --all-targets` and `cargo fmt --check`.

## Review smells

- `std::thread::sleep` or a real `SystemTime::now()` in a unit test.
- `mockall` expectations on query methods whose return value is all that matters. Use a fake instead.
- Testing private functions through `use super::*` when the public API could express the behaviour.
- `#[ignore]` without a reason string, or ignored tests nobody runs.
- `.unwrap()` hiding which step failed. Use `expect("given: …")` or return `Result<(), Box<dyn Error>>` from the test.
