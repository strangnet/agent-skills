# Python

## Running tests

- Use the project's runner: `uv run pytest` if there is a `uv.lock`, `poetry run pytest` with Poetry, otherwise `pytest`.
- Run a single test with `pytest path/to/test_cart.py::test_empty_cart_totals_zero`, or filter by name with `-k`.
- Use `-x` to stop at the first failure and `-q` for terse output.
- An `ImportError` or `NameError` for the code under test counts as red.

## Pending tests

```python
@pytest.mark.skip(reason="pending")
def test_single_item_totals_its_price(): ...
```

Use `pytest -rs` to list skipped tests with their reasons.

## Unit test shape

Tests live in `tests/test_<module>.py`, or in `test_*.py` files beside the module, following whatever the project already does.

```python
from shop.cart import Cart


class FakeCatalog:
    def __init__(self, prices: dict[str, int] | None = None) -> None:
        self._prices = prices or {}

    def price_of(self, sku: str) -> int | None:
        return self._prices.get(sku)


def test_empty_cart_totals_zero():
    # Given
    cart = Cart(FakeCatalog())

    # When
    total = cart.total()

    # Then
    assert total == 0
```

## Seams and test doubles

- The seam is a `typing.Protocol` in production code (`class PriceCatalog(Protocol): def price_of(self, sku: str) -> int | None: ...`). The fake satisfies it structurally, and a type checker (mypy or pyright) confirms it does.
- Prefer **hand-written fakes** over `unittest.mock`. When you do need a mock for interaction checks, use `create_autospec(PriceCatalog)` so a call with the wrong signature fails.
- Inject collaborators through `__init__` or function parameters. Patching module globals with `mock.patch` is a sign that a seam is missing, so raise it in refactor.
- Inject the clock (`now: Callable[[], datetime]`) rather than calling `datetime.now()` in domain code.
- Shared setup goes in `conftest.py` fixtures. Keep `Given` visible in the test body when it matters to the behaviour.

## Parameterised tests

```python
@pytest.mark.parametrize(
    ("qty", "price", "expected"),
    [(1, 250, 250), (3, 250, 750)],
    ids=["single unit", "three units"],
)
def test_quantity_multiplies_price(qty, price, expected):
    # Given / When / Then as usual
    ...
```

## Integration and contract tests

- Mark slow tests (`@pytest.mark.integration`, registered in `pyproject.toml`) and exclude them by default with `-m "not integration"`.
- Managed dependencies: `testcontainers` (the `testcontainers-python` package).
- Unmanaged HTTP dependencies: `respx` (for httpx) or `responses` (for requests) as stubs that assert on the request.
- Async: `pytest-asyncio` or `anyio`. Wait with a bounded poll, never `time.sleep`.

## Gotchas

- Money: use integer cents or `Decimal`. Compare floats with `pytest.approx`.
- Mutable default arguments (`prices={}`) leak state between tests. Use `None` plus a fallback, as the fake above does.
- Refactor phase: run `ruff check`, `ruff format` and the project's type checker.
