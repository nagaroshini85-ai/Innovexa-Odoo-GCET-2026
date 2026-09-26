-- StockSense data consistency checks. Read-only; run after the Postman workflow.

-- 1) Expected: zero rows. Compares current stock to the sum of all ledger movements.
WITH ledger_totals AS (
  SELECT product_id, location_id, SUM(quantity) AS ledger_quantity
  FROM stock_ledger
  GROUP BY product_id, location_id
), all_balances AS (
  SELECT product_id, location_id FROM stock
  UNION
  SELECT product_id, location_id FROM ledger_totals
)
SELECT b.product_id, p.sku, b.location_id, l.name AS location,
       COALESCE(s.quantity, 0) AS stock_quantity,
       COALESCE(t.ledger_quantity, 0) AS ledger_quantity
FROM all_balances b
JOIN products p ON p.id = b.product_id
JOIN locations l ON l.id = b.location_id
LEFT JOIN stock s ON s.product_id = b.product_id AND s.location_id = b.location_id
LEFT JOIN ledger_totals t ON t.product_id = b.product_id AND t.location_id = b.location_id
WHERE COALESCE(s.quantity, 0) <> COALESCE(t.ledger_quantity, 0)
ORDER BY p.sku, l.name;

-- 2) Expected: zero rows. The database stock constraint should prevent negatives.
SELECT product_id, location_id, quantity
FROM stock
WHERE quantity < 0;

-- 3) Expected: zero rows. A validated transfer's movements must net to zero.
SELECT reference_id, SUM(quantity) AS net_transfer_quantity
FROM stock_ledger
WHERE reference_type = 'TRANSFER'
GROUP BY reference_id
HAVING SUM(quantity) <> 0;

-- 4) Inspect the most recent movements (the newest are first).
SELECT sl.created_at, sl.reference_type, sl.reference_id, sl.movement_type,
       p.sku, p.name AS product, l.name AS location, sl.quantity, sl.notes
FROM stock_ledger sl
JOIN products p ON p.id = sl.product_id
JOIN locations l ON l.id = sl.location_id
ORDER BY sl.created_at DESC, sl.id DESC
LIMIT 50;
