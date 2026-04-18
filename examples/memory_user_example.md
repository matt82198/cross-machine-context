---
name: User Profile
description: Developer background, preferences, and working style
type: user
---

# User Profile

## Background
- Software engineer, 8 years experience
- Primary language: Python (data pipelines, backend APIs)
- Currently learning: Rust (systems programming, CLI tools)
- Comfortable with: Docker, PostgreSQL, basic AWS

## Preferences
- Prefers explicit types over implicit inference where the language allows
- Wants tests written before implementation (TDD)
- Prefers flat module structures over deeply nested packages
- Dislikes magic/metaprogramming — prefers readable over clever
- Comments should explain *why*, not *what*

## Working style
- Likes short feedback loops — run tests on every save if possible
- Prefers small PRs, incremental commits
- Will ask "why" before accepting a large refactor

## Stack defaults (when not specified)
- Python: `uv` for dependency management, `ruff` for lint/format, `pytest` for tests
- Rust: `cargo`, standard `clippy` + `rustfmt`
- CI: GitHub Actions

## Known gaps / learning edges
- Rust lifetime annotations still tricky — explain when introducing non-trivial lifetimes
- Unfamiliar with async Rust patterns — prefer sync unless there's a strong reason
