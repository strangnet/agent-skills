#!/usr/bin/env bash
set -euo pipefail
cat > pyproject.toml <<'T'
[project]
name = "shop"
version = "0.1.0"
requires-python = ">=3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
T
mkdir -p shop tests
: > shop/__init__.py
