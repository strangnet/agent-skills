# TypeScript

## Running tests

- Use the `test` script in `package.json` with the project's package manager (`pnpm test`, `npm test`, `bun test`). The examples here use **Vitest**. Jest's API is nearly identical (`jest.fn` instead of `vi.fn`).
- Run a single test with `vitest run src/cart.test.ts -t "totals zero when empty"`.
- **Vitest and most Jest setups strip types without checking them.** A type error is only red if you also run `tsc --noEmit` (or `vitest --typecheck`). Run it in red and green whenever the failure you expect is a type error.

## Pending tests

```ts
it.todo("totals the price of a single item");
```

Use `it.skip(...)` for a test that already has a body. Vitest reports both as pending.

## Unit test shape

```ts
import { describe, it, expect } from "vitest";
import { Cart, type PriceCatalog } from "./cart";

const fakeCatalog = (prices: Record<string, number> = {}): PriceCatalog => ({
  priceOf: (sku) => prices[sku],
});

describe("Cart", () => {
  it("totals zero when empty", () => {
    // Given
    const cart = new Cart(fakeCatalog());

    // When
    const total = cart.total();

    // Then
    expect(total).toBe(0);
  });

  it.todo("totals the price of a single item");
});
```

Name `describe`/`it` pairs so they read as a sentence: "Cart totals zero when empty".

## Seams and test doubles

- The seam is an **interface or type** (`interface PriceCatalog { priceOf(sku: string): number | undefined }`). Structural typing means a plain object literal is a valid fake, with no class needed.
- Prefer **hand-written fakes**, like `fakeCatalog` above. Use `vi.fn()` when you need to assert on calls, and type it (`vi.fn<PriceCatalog["priceOf"]>()`) so signature drift fails type-checking.
- Inject collaborators through constructors or function parameters. Module mocking (`vi.mock("./catalog")`) is a sign that a seam is missing, so raise it in refactor.
- Clock: inject `now: () => Date`, or use `vi.useFakeTimers()` with `vi.setSystemTime()` for code you do not own.

## Parameterised tests

```ts
it.each([
  { qty: 1, price: 250, expected: 250 },
  { qty: 3, price: 250, expected: 750 },
])("multiplies price by quantity ($qty × $price)", ({ qty, price, expected }) => {
  // Given / When / Then as usual
});
```

## Integration and contract tests

- Keep slow suites in a separate config or project (`vitest.integration.config.ts`) so the unit loop stays fast.
- Managed dependencies: `testcontainers` for Node.
- Unmanaged HTTP dependencies: `msw` (Mock Service Worker) as the stub server, asserting on request shape in the handler.
- Async: `await expect.poll(() => ...).toBe(...)` or `vi.waitFor`. Never use `setTimeout` sleeps.
- Presentation work: Testing Library (`@testing-library/react` and others). Query by role and accessible name, not by CSS selector.

## Gotchas

- Indexing a `Record<string, number>` gives `number | undefined` only with `noUncheckedIndexedAccess`. Check `tsconfig.json` before relying on it.
- Floating-point money: use integer cents.
- Refactor phase: run the project's linter (`eslint` or `biome`), its formatter and `tsc --noEmit`.
