# StockSense API test run guide

## 1. Prepare the local system

From the project root, apply the database files in this order to a fresh local database:

```sh
createdb stocksense
psql -d stocksense -f schema.sql
psql -d stocksense -f seed.sql
```

In `backend`, create `.env` from `.env.example`, set the local PostgreSQL password and a private JWT secret, then run:

```sh
npm install
npm run dev
```

Keep the backend terminal open. Check `http://localhost:5000/api/health`; it should return `{"status":"ok"}`.

## 2. Import the Postman files

1. Open Postman and choose **Import**.
2. Import `StockSense.postman_collection.json`.
3. Import `StockSense.postman_environment.json`.
4. Select the **StockSense Local** environment from the environment selector.
5. The environment uses the local seed account (`admin@example.com` / `ChangeMe123!`). These credentials are for the local demo database only.
6. Open the collection and run the folders in order, or run the entire collection with the Collection Runner.

The login request saves a JWT into the `token` environment variable. Collection-level bearer authorization sends it on protected requests. Setup requests find the seeded Steel Sheet product and locations by SKU/code, then capture the starting stock. The workflow test creates a receipt, delivery, transfer, and adjustment, and checks the balances and ledger.

## 3. Read the results

Postman displays each request status and each assertion. Expected negative tests return 400 or 409; those responses are passing results when the assertions pass. The tests confirm insufficient-stock rejection did not change stock. Run `verification.sql` in the same database to compare stock balances with summed ledger movements.

## 4. Keep Git safe

Commit the collection, environment template, Markdown test plans, and SQL verification query. Do not commit `backend/.env`, production tokens, or real credentials. The included demo login is already in the local seed data; remove/change it before deploying or sharing a live system.

## Current project assumptions

- The API listens on port 5000 and uses the `/api` prefix.
- Document statuses are `DRAFT`, `VALIDATED`, and `CANCELLED`.
- `STL-001`, `WH-001`, `WH-002`, `A-01`, and `P-01` are present in the supplied seed.
- Run against a local/demo database because the collection adds documents and ledger entries.
- The frontend at port 5173 is separate and must be started independently for UI integration tests.
