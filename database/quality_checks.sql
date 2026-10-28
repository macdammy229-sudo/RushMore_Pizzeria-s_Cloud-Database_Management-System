-- Validation queries and quality checks for RushMore PostgreSQL database

SELECT 'stores' AS table_name, COUNT(*) AS row_count FROM stores
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'ingredients', COUNT(*) FROM ingredients
UNION ALL
SELECT 'menu_items', COUNT(*) FROM menu_items
UNION ALL
SELECT 'menu_item_ingredients', COUNT(*) FROM menu_item_ingredients
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;

-- Duplicate email check
SELECT email, COUNT(*)
FROM customers
GROUP BY email
HAVING COUNT(*) > 1;

-- Duplicate store phone numbers
SELECT phone_number, COUNT(*)
FROM stores
GROUP BY phone_number
HAVING COUNT(*) > 1;

-- Orphaned orders with missing customer
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id IS NOT NULL AND c.customer_id IS NULL;

-- Orphaned order items with missing order
SELECT oi.order_item_id, oi.order_id
FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

-- Missing menu item references on order_items
SELECT oi.order_item_id, oi.item_id
FROM order_items oi
LEFT JOIN menu_items mi ON mi.item_id = oi.item_id
WHERE mi.item_id IS NULL;

-- Example query with index usage and explain plan
EXPLAIN ANALYZE
SELECT o.order_id, c.customer_id, c.email, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_timestamp >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY o.order_timestamp DESC
LIMIT 20;

-- Example retrieval by store and date range
EXPLAIN ANALYZE
SELECT s.store_id, s.city, COUNT(*) AS total_orders, ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM stores s
JOIN orders o ON o.store_id = s.store_id
WHERE o.order_timestamp >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY s.store_id, s.city
ORDER BY total_orders DESC;

-- Confirm required indexes
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items', 'menu_item_ingredients')
ORDER BY tablename, indexname;
