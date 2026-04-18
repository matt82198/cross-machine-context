---
name: Feedback — Don't Mock the Database
description: Real integration tests are preferred over mocked DB calls; mocking hides bugs
type: feedback
---

# Feedback: Don't Mock the Database

## Rule
Do not mock database calls in tests. Use a real database (in-process SQLite or
a Docker-managed Postgres) for integration and service-layer tests.

## Rationale
- Mocks hide mismatches between query logic and the actual schema
- ORM query bugs, migration drift, and constraint violations are invisible
  behind mocks — they only surface in production
- Test setup with a real DB is slightly more work but catches real bugs

## What to do instead
- Unit tests (pure functions, no I/O): mocks are fine
- Service/repository layer tests: spin up an in-process DB or a Docker fixture
- Use `pytest-docker` or `testcontainers` for Postgres in CI
- Use SQLite in-memory (`:memory:`) only when the SQL is genuinely
  database-agnostic and no Postgres-specific features are used

## When this was established
Caught after a migration dropped a NOT NULL column and all tests still passed
because the repository layer was fully mocked. The bug reached staging.

## Date added
2025-11-03
