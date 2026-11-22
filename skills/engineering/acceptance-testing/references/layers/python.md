# Python: acceptance layers

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
  dsl/__init__.py
  dsl/aliases.py               alias helper
  dsl/dsl.py                   driver interface, DSL root, domain areas
  drivers.py                   HTTP driver + factory
  conftest.py                  `dsl` fixture: one per test
  test_checkout.py             scenario without Gherkin
  features/checkout.feature
  test_checkout_feature.py     scenario with Gherkin (pytest-bdd)
```

`pytest` and `httpx`, plus `pytest-bdd` if Gherkin is used. `pytest-bdd` keeps everything in one runner and reuses pytest fixtures. If the project already uses `behave`, its steps call the same DSL.

**Failure convention:** the driver raises `AssertionError` with a descriptive message, and pytest reports it as a test failure.

## Alias helper

`acceptance/dsl/aliases.py`

```python
import itertools
import uuid

_run = uuid.uuid4().hex[:6]
_seq = itertools.count(1)


class Aliases:
    """Maps the plain names a scenario uses to names unique to this test.

    The same name maps to the same alias for the whole test.
    """

    def __init__(self) -> None:
        self._map: dict[str, str] = {}

    def __call__(self, name: str) -> str:
        if name not in self._map:
            self._map[name] = f"{name}-{_run}-{next(_seq)}"
        return self._map[name]
```

## DSL and driver interface

`acceptance/dsl/__init__.py`

```python
from acceptance.dsl.dsl import Dsl, Driver

__all__ = ["Dsl", "Driver"]
```

`acceptance/dsl/dsl.py`

```python
from decimal import Decimal
from typing import Protocol

from acceptance.dsl.aliases import Aliases


class Driver(Protocol):
    """Protocol driver contract. Methods raise AssertionError when the system misbehaves."""

    def register_customer(self, name: str) -> None: ...
    def create_product(self, name: str, price_cents: int) -> None: ...
    def place_order(self, customer: str, product: str) -> None: ...
    def confirm_last_charge(self, customer: str, amount_cents: int) -> None: ...


def _cents(amount: str) -> int:
    return int(Decimal(amount) * 100)


class Customer:
    def __init__(self, driver: Driver, aliases: Aliases) -> None:
        self._driver = driver
        self._alias = aliases
        self._current = ""  # bridging state: the customer later steps refer to

    def is_registered(self, name: str = "customer") -> None:
        self._current = self._alias(name)
        self._driver.register_customer(self._current)

    def buys(self, product: str) -> None:
        self._driver.place_order(self._current, self._alias(product))

    def confirm_charged(self, amount: str) -> None:
        self._driver.confirm_last_charge(self._current, _cents(amount))


class Catalog:
    def __init__(self, driver: Driver, aliases: Aliases) -> None:
        self._driver = driver
        self._alias = aliases

    def has_product(self, name: str, price: str = "10.00") -> None:
        self._driver.create_product(self._alias(name), _cents(price))


class Dsl:
    """What scenarios talk to. Create one per test."""

    def __init__(self, driver: Driver) -> None:
        aliases = Aliases()
        self.customer = Customer(driver, aliases)
        self.catalog = Catalog(driver, aliases)
```

## HTTP driver and factory

`acceptance/drivers.py`

```python
import os
import time
from collections.abc import Callable
from urllib.parse import quote

import httpx

from acceptance.dsl import Driver


def driver_from_env() -> Driver:
    kind = os.environ.get("ACCEPTANCE_DRIVER", "http")
    if kind == "http":
        return HttpDriver(os.environ.get("SUT_URL", "http://localhost:8080"))
    raise ValueError(f"unknown ACCEPTANCE_DRIVER {kind!r}")


class HttpDriver:
    def __init__(self, base_url: str) -> None:
        self._http = httpx.Client(base_url=base_url, timeout=5)

    def register_customer(self, name: str) -> None:
        self._post("/customers", {"name": name, "email": f"{name}@example.test"})

    def create_product(self, name: str, price_cents: int) -> None:
        self._post("/products", {"name": name, "price_cents": price_cents})

    def place_order(self, customer: str, product: str) -> None:
        self._post("/orders", {"customer": customer, "product": product})

    def confirm_last_charge(self, customer: str, amount_cents: int) -> None:
        # The system is the single source of truth; orders settle asynchronously.
        def check() -> None:
            r = self._http.get(f"/customers/{quote(customer)}/orders/latest")
            r.raise_for_status()
            charged = r.json()["charged_cents"]
            assert charged == amount_cents, (
                f"{customer} was charged {charged} cents, expected {amount_cents}"
            )

        _eventually(check)

    def _post(self, path: str, body: dict[str, object]) -> None:
        r = self._http.post(path, json=body)
        assert r.is_success, f"POST {path}: {r.status_code} {r.text}"


def _eventually(check: Callable[[], None], timeout: float = 5.0, interval: float = 0.1) -> None:
    deadline = time.monotonic() + timeout
    while True:
        try:
            return check()
        except AssertionError:
            if time.monotonic() >= deadline:
                raise
            time.sleep(interval)
```

## Fixture

`acceptance/conftest.py`

```python
import pytest

from acceptance.dsl import Dsl
from acceptance.drivers import driver_from_env


@pytest.fixture
def dsl() -> Dsl:
    return Dsl(driver_from_env())
```

## Scenario without Gherkin

`acceptance/test_checkout.py`

```python
from acceptance.dsl import Dsl


def test_orders_at_the_threshold_get_ten_percent_off(dsl: Dsl):
    # Given
    dsl.customer.is_registered()
    dsl.catalog.has_product("Desk lamp", price="100.00")

    # When
    dsl.customer.buys("Desk lamp")

    # Then
    dsl.customer.confirm_charged("90.00")
```

## Scenario with Gherkin (pytest-bdd)

`acceptance/test_checkout_feature.py`

```python
from pytest_bdd import given, parsers, scenarios, then, when

scenarios("features/checkout.feature")


@given("a registered customer")
def registered_customer(dsl):
    dsl.customer.is_registered()


@given(parsers.parse('a product "{name}" priced at {price}'))
def product_priced_at(dsl, name, price):
    dsl.catalog.has_product(name, price=price)


@when(parsers.parse('the customer buys "{name}"'))
def customer_buys(dsl, name):
    dsl.customer.buys(name)


@then(parsers.parse("the customer is charged {amount}"))
def customer_is_charged(dsl, amount):
    dsl.customer.confirm_charged(amount)
```

## Running

- `SUT_URL=http://localhost:8080 pytest acceptance`
- Run in parallel with `pytest-xdist` (`-n auto`). This is safe because every test works in its own aliased partition.
- Mark the suite (`pytestmark = pytest.mark.acceptance`) so the unit run can exclude it.
