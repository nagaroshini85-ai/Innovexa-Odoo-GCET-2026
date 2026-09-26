# StockSense inventory workflow test

This is the manual end-to-end inventory acceptance test owned by Person 4. It follows the seeded Steel Sheet (`STL-001`) through the backend API. The matching automated request sequence is in `StockSense.postman_collection.json`.

## Seed locations

- Source: `WH-001` / `A-01` (Main Warehouse / Rack A)
- Destination: `WH-002` / `P-01` (Production Warehouse / Production Rack)
- Product canonical unit: read `unit_of_measure` from `GET /api/products` (the seed uses `kg` for Steel Sheet).

Capture the initial source quantity as **S** and destination quantity as **D** from `GET /api/products/:id`. Do not assume the database is fresh; the Postman collection captures the live baseline each run.

## Run the workflow

Use an authenticated admin token and the IDs returned by `GET /api/warehouses` and `GET /api/products`.

1. Create and validate a receipt for 10 units into the source location.
2. Create and validate a delivery for 2 units from the source location.
3. Create and validate a transfer for 3 units from source to destination.
4. Create and validate an adjustment at source to physical quantity `S + 4`.
5. Read the product detail, dashboard summary, and product ledger.

Expected final quantities:

| Location | Expected quantity |
|---|---:|
| Source (Rack A) | `S + 4` |
| Destination (Production Rack) | `D + 3` |
| Combined source + destination | `S + D + 7` |

Expected ledger movements for this run:

| Type | Quantity | Location |
|---|---:|---|
| `RECEIPT` | `+10` | Source |
| `DELIVERY` | `-2` | Source |
| `TRANSFER_OUT` | `-3` | Source |
| `TRANSFER_IN` | `+3` | Destination |
| `ADJUSTMENT` | `-1` | Source |

The transfer pair nets to zero. The final total is seven units higher than the initial total because receipt adds ten, delivery removes two, and the adjustment removes one.

## Negative stock protection

Capture Rack A quantity after the workflow. Create a draft delivery with quantity `999999` and validate it. Validation must return HTTP 409, and a fresh `GET /api/products/:id` must show the exact same Rack A quantity as before that rejected validation. The draft document may remain in `DRAFT` after the failed transaction; the stock and ledger must not change.

## Data integrity check

Run `verification.sql`. Its first three checks should return no rows: stock matches ledger totals, no stock is negative, and each transfer's ledger movements net to zero. If any query returns rows, save the response and report the request/document ID to Person 2; do not edit stock or delete ledger history to make the check pass.
