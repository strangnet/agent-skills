# TypeScript: acceptance layers

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
  dsl/aliases.ts                  alias helper
  dsl/dsl.ts                      driver interface, DSL root, domain areas
  drivers.ts                      HTTP driver + factory
  checkout.test.ts                scenario without Gherkin (Vitest)
  features/checkout.feature
  features/steps/checkout.steps.ts  scenario with Gherkin (Cucumber.js)
```

Node 18+ (global `fetch`) and Vitest, plus `@cucumber/cucumber` and `tsx` if Gherkin is used. For UI drivers, Playwright can host the scenarios instead, with the DSL unchanged.

**Failure convention:** driver methods return promises that reject with an `Error` carrying a descriptive message. Every DSL call in a scenario is awaited.

## Alias helper

`acceptance/dsl/aliases.ts`

```ts
const run = Math.random().toString(36).slice(2, 8);
let seq = 0;

/**
 * Maps the plain names a scenario uses to names unique to this test.
 * The same name maps to the same alias for the whole test.
 */
export class Aliases {
  private readonly map = new Map<string, string>();

  alias(name: string): string {
    let value = this.map.get(name);
    if (value === undefined) {
      value = `${name}-${run}-${++seq}`;
      this.map.set(name, value);
    }
    return value;
  }
}
```

## DSL and driver interface

DSL methods take an options object, so a scenario passes only the values it cares about and the rest fall back to defaults.

`acceptance/dsl/dsl.ts`

```ts
import { Aliases } from "./aliases.ts";

/** Protocol driver contract. Methods reject with an Error when the system misbehaves. */
export interface Driver {
  registerCustomer(name: string): Promise<void>;
  createProduct(name: string, priceCents: number): Promise<void>;
  placeOrder(customer: string, product: string): Promise<void>;
  confirmLastCharge(customer: string, amountCents: number): Promise<void>;
}

const toCents = (amount: string): number => Math.round(Number(amount) * 100);

class Customer {
  private current = ""; // bridging state: the customer later steps refer to

  constructor(private readonly driver: Driver, private readonly aliases: Aliases) {}

  async isRegistered({ name = "customer" }: { name?: string } = {}): Promise<void> {
    this.current = this.aliases.alias(name);
    await this.driver.registerCustomer(this.current);
  }

  buys(product: string): Promise<void> {
    return this.driver.placeOrder(this.current, this.aliases.alias(product));
  }

  confirmCharged(amount: string): Promise<void> {
    return this.driver.confirmLastCharge(this.current, toCents(amount));
  }
}

class Catalog {
  constructor(private readonly driver: Driver, private readonly aliases: Aliases) {}

  hasProduct({ name, price = "10.00" }: { name: string; price?: string }): Promise<void> {
    return this.driver.createProduct(this.aliases.alias(name), toCents(price));
  }
}

/** What scenarios talk to. Create one per test. */
export class Dsl {
  readonly customer: Customer;
  readonly catalog: Catalog;

  constructor(driver: Driver) {
    const aliases = new Aliases();
    this.customer = new Customer(driver, aliases);
    this.catalog = new Catalog(driver, aliases);
  }
}
```

## HTTP driver and factory

`acceptance/drivers.ts`

```ts
import type { Driver } from "./dsl/dsl.ts";

export function driverFromEnv(): Driver {
  const kind = process.env.ACCEPTANCE_DRIVER ?? "http";
  if (kind === "http") return new HttpDriver(process.env.SUT_URL ?? "http://localhost:8080");
  throw new Error(`unknown ACCEPTANCE_DRIVER "${kind}"`);
}

class HttpDriver implements Driver {
  constructor(private readonly baseUrl: string) {}

  registerCustomer(name: string) {
    return this.post("/customers", { name, email: `${name}@example.test` });
  }

  createProduct(name: string, priceCents: number) {
    return this.post("/products", { name, price_cents: priceCents });
  }

  placeOrder(customer: string, product: string) {
    return this.post("/orders", { customer, product });
  }

  // The system is the single source of truth; orders settle asynchronously.
  confirmLastCharge(customer: string, amountCents: number) {
    return eventually(async () => {
      const res = await fetch(`${this.baseUrl}/customers/${encodeURIComponent(customer)}/orders/latest`);
      if (!res.ok) throw new Error(`GET latest order: ${res.status}`);
      const { charged_cents } = (await res.json()) as { charged_cents: number };
      if (charged_cents !== amountCents) {
        throw new Error(`${customer} was charged ${charged_cents} cents, expected ${amountCents}`);
      }
    });
  }

  private async post(path: string, body: unknown): Promise<void> {
    const res = await fetch(`${this.baseUrl}${path}`, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`POST ${path}: ${res.status} ${await res.text()}`);
  }
}

async function eventually(check: () => Promise<void>, timeoutMs = 5000, intervalMs = 100) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    try {
      return await check();
    } catch (err) {
      if (Date.now() >= deadline) throw err;
      await new Promise((r) => setTimeout(r, intervalMs));
    }
  }
}
```

## Scenario without Gherkin

`acceptance/checkout.test.ts`

```ts
import { it } from "vitest";
import { Dsl } from "./dsl/dsl.ts";
import { driverFromEnv } from "./drivers.ts";

it.concurrent("orders at the threshold get ten percent off", async () => {
  const dsl = new Dsl(driverFromEnv());

  // Given
  await dsl.customer.isRegistered();
  await dsl.catalog.hasProduct({ name: "Desk lamp", price: "100.00" });

  // When
  await dsl.customer.buys("Desk lamp");

  // Then
  await dsl.customer.confirmCharged("90.00");
});
```

## Scenario with Gherkin (Cucumber.js)

`acceptance/features/steps/checkout.steps.ts`

```ts
import { Given, Then, When, World, setWorldConstructor } from "@cucumber/cucumber";
import { Dsl } from "../../dsl/dsl.ts";
import { driverFromEnv } from "../../drivers.ts";

// Cucumber builds a fresh World per scenario, so each scenario gets its own DSL and aliases.
class ShopWorld extends World {
  readonly dsl = new Dsl(driverFromEnv());
}
setWorldConstructor(ShopWorld);

Given("a registered customer", function (this: ShopWorld) {
  return this.dsl.customer.isRegistered();
});

Given("a product {string} priced at {word}", function (this: ShopWorld, name: string, price: string) {
  return this.dsl.catalog.hasProduct({ name, price });
});

When("the customer buys {string}", function (this: ShopWorld, name: string) {
  return this.dsl.customer.buys(name);
});

Then("the customer is charged {word}", function (this: ShopWorld, amount: string) {
  return this.dsl.customer.confirmCharged(amount);
});
```

## Running

- Without Gherkin: `SUT_URL=http://localhost:8080 vitest run acceptance`. Keep a separate Vitest project or config so unit runs stay fast.
- With Gherkin: `SUT_URL=… NODE_OPTIONS="--import tsx" cucumber-js --import 'acceptance/features/steps/*.ts' acceptance/features`
- The module-level run id in `aliases.ts` is generated per worker, so aliases stay unique under Vitest's parallel workers.
