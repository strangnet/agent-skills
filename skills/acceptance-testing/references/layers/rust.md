# Rust: acceptance layers

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
tests/
  acceptance/mod.rs        declares the modules below
  acceptance/aliases.rs    alias helper
  acceptance/dsl.rs        driver trait, DSL root, domain areas
  acceptance/drivers.rs    HTTP driver + factory
  checkout.rs              scenario without Gherkin
  features/checkout.feature
  features.rs              scenario with Gherkin (cucumber crate)
```

`tests/acceptance/` is a shared module, not a test target. Each `tests/*.rs` file pulls it in with `mod acceptance;`.

`Cargo.toml (dev-dependencies)`

```toml
[dev-dependencies]
ureq = { version = "2", features = ["json"] }
serde_json = "1"
cucumber = "0.21"
futures = "0.3"

[[test]]
name = "features"
harness = false
```

`ureq` is a blocking client with no async runtime, so the same driver works in plain `#[test]` functions and inside the cucumber runner. If Gherkin is not used, drop `cucumber`, `futures` and the `[[test]]` entry.

**Failure convention:** driver methods panic with a descriptive message, and the panic fails the test.

## Alias helper

`tests/acceptance/aliases.rs`

```rust
use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::OnceLock;
use std::time::{SystemTime, UNIX_EPOCH};

static SEQ: AtomicU64 = AtomicU64::new(1);

fn run_id() -> u64 {
    static RUN: OnceLock<u64> = OnceLock::new();
    *RUN.get_or_init(|| {
        let nanos = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_nanos();
        (nanos % 1_000_000) as u64
    })
}

/// Maps the plain names a scenario uses to names unique to this test.
/// The same name maps to the same alias for the whole test.
#[derive(Default)]
pub struct Aliases(HashMap<String, String>);

impl Aliases {
    pub fn alias(&mut self, name: &str) -> String {
        self.0
            .entry(name.to_owned())
            .or_insert_with(|| format!("{name}-{}-{}", run_id(), SEQ.fetch_add(1, Ordering::Relaxed)))
            .clone()
    }
}
```

## DSL and driver trait

The domain areas borrow the DSL root mutably (`dsl.customer().buys(…)`), so they share one alias map and one set of bridging state without `Rc<RefCell<_>>`.

`tests/acceptance/dsl.rs`

```rust
use super::aliases::Aliases;

/// Protocol driver contract. Methods panic with a descriptive message when the
/// system misbehaves, which fails the test.
pub trait Driver {
    fn register_customer(&self, name: &str);
    fn create_product(&self, name: &str, price_cents: u64);
    fn place_order(&self, customer: &str, product: &str);
    fn confirm_last_charge(&self, customer: &str, amount_cents: u64);
}

/// What scenarios talk to. Create one per test.
pub struct Dsl {
    driver: Box<dyn Driver>,
    aliases: Aliases,
    current_customer: String, // bridging state: the customer later steps refer to
}

impl Dsl {
    pub fn new(driver: Box<dyn Driver>) -> Self {
        Self { driver, aliases: Aliases::default(), current_customer: String::new() }
    }

    pub fn customer(&mut self) -> Customer<'_> {
        Customer(self)
    }

    pub fn catalog(&mut self) -> Catalog<'_> {
        Catalog(self)
    }
}

pub struct Customer<'a>(&'a mut Dsl);

impl Customer<'_> {
    pub fn is_registered(self) {
        let name = self.0.aliases.alias("customer");
        self.0.driver.register_customer(&name);
        self.0.current_customer = name;
    }

    pub fn buys(self, product: &str) {
        let product = self.0.aliases.alias(product);
        self.0.driver.place_order(&self.0.current_customer, &product);
    }

    pub fn confirm_charged(self, amount: &str) {
        self.0.driver.confirm_last_charge(&self.0.current_customer, cents(amount));
    }
}

pub struct Catalog<'a>(&'a mut Dsl);

impl Catalog<'_> {
    pub fn has_product(self, name: &str, price: &str) {
        let name = self.0.aliases.alias(name);
        self.0.driver.create_product(&name, cents(price));
    }
}

fn cents(amount: &str) -> u64 {
    let (whole, frac) = amount.split_once('.').unwrap_or((amount, "0"));
    let frac = format!("{frac:0<2}");
    let parse = |s: &str| s.parse::<u64>().unwrap_or_else(|_| panic!("bad amount {amount:?}"));
    parse(whole) * 100 + parse(&frac[..2])
}
```

## HTTP driver and factory

`tests/acceptance/drivers.rs`

```rust
use std::thread::sleep;
use std::time::{Duration, Instant};

use serde_json::{json, Value};

use super::dsl::Driver;

pub fn from_env() -> Box<dyn Driver> {
    match std::env::var("ACCEPTANCE_DRIVER").as_deref() {
        Err(_) | Ok("http") => {
            let base = std::env::var("SUT_URL").unwrap_or_else(|_| "http://localhost:8080".into());
            Box::new(HttpDriver { base })
        }
        Ok(other) => panic!("unknown ACCEPTANCE_DRIVER {other:?}"),
    }
}

pub struct HttpDriver {
    base: String,
}

impl HttpDriver {
    fn post(&self, path: &str, body: Value) {
        if let Err(e) = ureq::post(&format!("{}{path}", self.base)).send_json(body) {
            panic!("POST {path}: {e}");
        }
    }
}

impl Driver for HttpDriver {
    fn register_customer(&self, name: &str) {
        self.post("/customers", json!({ "name": name, "email": format!("{name}@example.test") }));
    }

    fn create_product(&self, name: &str, price_cents: u64) {
        self.post("/products", json!({ "name": name, "price_cents": price_cents }));
    }

    fn place_order(&self, customer: &str, product: &str) {
        self.post("/orders", json!({ "customer": customer, "product": product }));
    }

    // The system is the single source of truth; orders settle asynchronously.
    fn confirm_last_charge(&self, customer: &str, amount_cents: u64) {
        let url = format!("{}/customers/{customer}/orders/latest", self.base);
        eventually(Duration::from_secs(5), || {
            let body: Value = ureq::get(&url)
                .call()
                .map_err(|e| e.to_string())?
                .into_json()
                .map_err(|e| e.to_string())?;
            match body["charged_cents"].as_u64() {
                Some(c) if c == amount_cents => Ok(()),
                other => Err(format!("{customer} was charged {other:?} cents, expected {amount_cents}")),
            }
        });
    }
}

fn eventually(timeout: Duration, mut check: impl FnMut() -> Result<(), String>) {
    let deadline = Instant::now() + timeout;
    loop {
        match check() {
            Ok(()) => return,
            Err(e) if Instant::now() >= deadline => panic!("{e}"),
            Err(_) => sleep(Duration::from_millis(100)),
        }
    }
}
```

`tests/acceptance/mod.rs`

```rust
pub mod aliases;
pub mod drivers;
pub mod dsl;
```

## Scenario without Gherkin

`tests/checkout.rs`

```rust
mod acceptance;

use acceptance::{drivers, dsl::Dsl};

#[test]
fn orders_at_the_threshold_get_ten_percent_off() {
    let mut dsl = Dsl::new(drivers::from_env());

    // Given
    dsl.customer().is_registered();
    dsl.catalog().has_product("Desk lamp", "100.00");

    // When
    dsl.customer().buys("Desk lamp");

    // Then
    dsl.customer().confirm_charged("90.00");
}
```

## Scenario with Gherkin (cucumber crate)

`tests/features.rs`

```rust
mod acceptance;

use acceptance::{drivers, dsl::Dsl};
use cucumber::{given, then, when, World};

// Cucumber builds a fresh World per scenario, so each scenario gets its own DSL and aliases.
#[derive(World)]
#[world(init = Self::new)]
struct ShopWorld {
    dsl: Dsl,
}

impl ShopWorld {
    fn new() -> Self {
        Self { dsl: Dsl::new(drivers::from_env()) }
    }
}

impl std::fmt::Debug for ShopWorld {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("ShopWorld")
    }
}

#[given("a registered customer")]
fn registered_customer(w: &mut ShopWorld) {
    w.dsl.customer().is_registered();
}

#[given(expr = "a product {string} priced at {word}")]
fn product_priced_at(w: &mut ShopWorld, name: String, price: String) {
    w.dsl.catalog().has_product(&name, &price);
}

#[when(expr = "the customer buys {string}")]
fn customer_buys(w: &mut ShopWorld, name: String) {
    w.dsl.customer().buys(&name);
}

#[then(expr = "the customer is charged {word}")]
fn customer_is_charged(w: &mut ShopWorld, amount: String) {
    w.dsl.customer().confirm_charged(&amount);
}

fn main() {
    futures::executor::block_on(ShopWorld::run("tests/features"));
}
```

## Running

- `SUT_URL=http://localhost:8080 cargo test --test checkout --test features`
- Keep acceptance targets out of the default `cargo test` with `required-features = ["acceptance"]` on each `[[test]]`, or run them in a separate CI job.
