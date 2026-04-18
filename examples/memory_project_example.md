---
name: Project — Inventory Sync Service
description: In-progress service that syncs product inventory from warehouse API to internal DB
type: project
---

# Project: Inventory Sync Service

## Status
In progress — core sync loop complete, retry logic in review

## Location
`~/projects/inventory-sync/`

## What it does
Polls the warehouse REST API every 5 minutes and upserts product inventory
counts into the internal Postgres `inventory` table. Emits a change event
to a Redis stream when a SKU's count crosses a low-stock threshold.

## Architecture
```
WarehouseAPIClient → SyncWorker → InventoryRepository → Postgres
                                        ↓
                               ThresholdChecker → RedisStream
```

## Current state (as of 2026-01-15)
- `WarehouseAPIClient`: done, tested
- `InventoryRepository`: done, tested with real Postgres (testcontainers)
- `SyncWorker`: core loop done, retry/backoff PR open (#12)
- `ThresholdChecker`: not started
- `RedisStream` publisher: stub only

## Known issues / open questions
- Warehouse API returns a 202 for large catalogs (>10k SKUs) and requires
  polling a job ID — current client doesn't handle this yet (ticket #14)
- Redis connection pooling not configured — fine for now, needs attention
  before production

## Next steps
1. Merge PR #12 (retry logic)
2. Implement async job polling in `WarehouseAPIClient` (ticket #14)
3. Build `ThresholdChecker` + Redis publisher
4. Write end-to-end integration test with mocked warehouse + real Redis

## Date added
2026-01-10
