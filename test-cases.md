# StockSense test cases

These cases target the current backend API and the database contract in the project README. API paths use `http://localhost:5000/api`; protected requests need `Authorization: Bearer <token>`.

## Preconditions

- Start PostgreSQL and create the `stocksense` database.
- Apply `schema.sql`, then `seed.sql` from the project root.
- Start the backend and confirm `/api/health` returns `{"status":"ok"}`.
- Seed data includes product `STL-001` (Steel Sheet), warehouses `WH-001` and `WH-002`, location `A-01` and location `P-01`, and local demo admin `admin@example.com`.
- Import `StockSense.postman_collection.json` and `StockSense.postman_environment.json`; select the `StockSense Local` environment.

The Postman collection captures the initial stock before each run, so it can be run repeatedly against the same local database. It creates test documents and ledger rows; use a disposable/local database.

## Core workflow cases

| ID | Action | Expected result |
|---|---|---|
| TC-001 | Log in as the seeded admin | 200 response and JWT token returned |
| TC-002 | List products and warehouses | Seed product, warehouses, and locations are returned |
| TC-003 | Create a receipt for 10 units at Rack A | 201; document status is `DRAFT`; stock is unchanged until validation |
| TC-004 | Validate the receipt | 200; status becomes `VALIDATED`; Rack A increases by 10; ledger records `RECEIPT +10` |
| TC-005 | Validate the same receipt again | 409; no additional stock or ledger movement |
| TC-006 | Create and validate a delivery for 2 units | 201 then 200; Rack A decreases by 2; ledger records `DELIVERY -2` |
| TC-007 | Validate the same delivery again | 409; no additional stock or ledger movement |
| TC-008 | Transfer 3 units from Rack A to Production Rack | Source decreases by 3, destination increases by 3; total quantity remains constant; ledger has `TRANSFER_OUT -3` and `TRANSFER_IN +3` |
| TC-009 | Adjust Rack A count down by 1 from the calculated balance | Stock equals physical count; ledger records `ADJUSTMENT -1` |
| TC-010 | Read product ledger | Receipt, delivery, transfer, and adjustment movements appear |
| TC-011 | Read dashboard summary | Response includes all six documented KPI fields |

For the collection’s full run, the expected source balance is:

```text
starting Rack A quantity + 10 receipt - 2 delivery - 3 transfer out - 1 adjustment
```

The expected Production Rack balance is:

```text
starting Production Rack quantity + 3 transfer in
```

## Validation and error cases

| ID | Action | Expected result |
|---|---|---|
| TC-012 | Create a delivery larger than available stock, then validate | Validation returns 409; stock remains unchanged |
| TC-013 | Transfer from a location to itself | 400 response |
| TC-014 | Create an adjustment with a negative physical count | 400 response |
| TC-015 | Create receipt/delivery/transfer with quantity 0 or negative | 400 response |
| TC-016 | Submit a mismatched product unit | 400 response |
| TC-017 | Put an operation item in a different warehouse than its document | 400 response |
| TC-018 | Validate a canceled or already validated document | 409 response |
| TC-019 | Request a missing product/document ID | 404 response |
| TC-020 | Make a protected request without a token | 401 response |

## Manual completion checklist

- [ ] Product search and stock by location match PostgreSQL.
- [ ] Receipt changes stock only after validation.
- [ ] Delivery and transfer reject insufficient stock without partial updates.
- [ ] Transfer source and destination changes net to zero across the company.
- [ ] Positive, negative, and zero adjustments behave correctly (zero adjustment creates no ledger movement).
- [ ] Validated documents cannot be validated twice.
- [ ] The ledger and stock verification query in `verification.sql` show no mismatches.
- [ ] Frontend actions call the same API endpoints and display returned errors.
