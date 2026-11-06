-- Validation queries and quality checks for RushMore PostgreSQL database.
-- The DO block makes data and integrity failures return a non-zero psql exit status.

DO $$
DECLARE
    expected record;
    actual_count BIGINT;
    violations BIGINT;
BEGIN
    FOR expected IN
        SELECT * FROM (VALUES
            ('stores', 4::BIGINT),
            ('customers', 6500::BIGINT),
            ('ingredients', 45::BIGINT),
            ('menu_items', 25::BIGINT),
            ('orders', 30000::BIGINT),
            ('order_items', 75000::BIGINT)
        ) AS counts(table_name, expected_count)
    LOOP
        EXECUTE format('SELECT count(*) FROM %I', expected.table_name) INTO actual_count;
        IF actual_count <> expected.expected_count THEN
            RAISE EXCEPTION 'Expected % rows in %, found %',
                expected.expected_count, expected.table_name, actual_count;
        END IF;
    END LOOP;

    SELECT count(*) INTO violations
    FROM (
        SELECT email FROM customers GROUP BY email HAVING count(*) > 1
        UNION ALL
        SELECT phone_number FROM customers GROUP BY phone_number HAVING count(*) > 1
        UNION ALL
        SELECT phone_number FROM stores GROUP BY phone_number HAVING count(*) > 1
    ) AS duplicates;
    IF violations > 0 THEN
        RAISE EXCEPTION 'Duplicate customer email/phone or store phone values found';
    END IF;

    SELECT count(*) INTO violations
    FROM orders o
    LEFT JOIN customers c ON c.customer_id = o.customer_id
    LEFT JOIN stores s ON s.store_id = o.store_id
    WHERE (o.customer_id IS NOT NULL AND c.customer_id IS NULL)
       OR s.store_id IS NULL;
    IF violations > 0 THEN
        RAISE EXCEPTION 'Found % orders with orphaned customer/store references', violations;
    END IF;

    SELECT count(*) INTO violations
    FROM order_items oi
    LEFT JOIN orders o ON o.order_id = oi.order_id
    LEFT JOIN menu_items mi ON mi.item_id = oi.item_id
    WHERE o.order_id IS NULL OR mi.item_id IS NULL
       OR oi.quantity <= 0 OR oi.unit_price < 0;
    IF violations > 0 THEN
        RAISE EXCEPTION 'Found % invalid order items', violations;
    END IF;

    SELECT count(*) INTO violations
    FROM menu_item_ingredients mii
    LEFT JOIN menu_items mi ON mi.item_id = mii.menu_item_id
    LEFT JOIN ingredients i ON i.ingredient_id = mii.ingredient_id
    WHERE mi.item_id IS NULL OR i.ingredient_id IS NULL OR mii.quantity <= 0;
    IF violations > 0 THEN
        RAISE EXCEPTION 'Found % invalid menu-item ingredient references or quantities', violations;
    END IF;

    IF to_regclass('public.idx_orders_customer_id') IS NULL
       OR to_regclass('public.idx_orders_store_id') IS NULL
       OR to_regclass('public.idx_orders_timestamp') IS NULL
       OR to_regclass('public.idx_order_items_order_id') IS NULL
       OR to_regclass('public.idx_order_items_item_id') IS NULL
       OR to_regclass('public.idx_menu_item_ingredients_ingredient_id') IS NULL THEN
        RAISE EXCEPTION 'One or more expected supporting indexes are missing';
    END IF;
END $$;

SELECT 'stores' AS table_name, COUNT(*) AS row_count FROM stores
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'ingredients', COUNT(*) FROM ingredients
UNION ALL SELECT 'menu_items', COUNT(*) FROM menu_items
UNION ALL SELECT 'menu_item_ingredients', COUNT(*) FROM menu_item_ingredients
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;

-- Detailed duplicate and orphan checks (should return no rows).
SELECT email AS duplicate_value, 'customer email' AS issue
FROM customers GROUP BY email HAVING COUNT(*) > 1
UNION ALL
SELECT phone_number, 'customer phone'
FROM customers GROUP BY phone_number HAVING COUNT(*) > 1
UNION ALL
SELECT phone_number, 'store phone'
FROM stores GROUP BY phone_number HAVING COUNT(*) > 1;

SELECT o.order_id, o.customer_id, o.store_id
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN stores s ON s.store_id = o.store_id
WHERE (o.customer_id IS NOT NULL AND c.customer_id IS NULL) OR s.store_id IS NULL;

SELECT oi.order_item_id, oi.order_id, oi.item_id
FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN menu_items mi ON mi.item_id = oi.item_id
WHERE o.order_id IS NULL OR mi.item_id IS NULL;

SELECT mii.menu_item_id, mii.ingredient_id
FROM menu_item_ingredients mii
LEFT JOIN menu_items mi ON mi.item_id = mii.menu_item_id
LEFT JOIN ingredients i ON i.ingredient_id = mii.ingredient_id
WHERE mi.item_id IS NULL OR i.ingredient_id IS NULL OR mii.quantity <= 0;

-- Example query plans for recent orders and store/date reporting.
EXPLAIN ANALYZE
SELECT o.order_id, c.customer_id, c.email, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_timestamp >= CURRENT_DATE - INTERVAL '30 days'
ORDER BY o.order_timestamp DESC
LIMIT 20;

EXPLAIN ANALYZE
SELECT s.store_id, s.city, COUNT(*) AS total_orders,
       ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM stores s
JOIN orders o ON o.store_id = s.store_id
WHERE o.order_timestamp >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY s.store_id, s.city
ORDER BY total_orders DESC;

SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN ('orders', 'order_items', 'menu_item_ingredients')
ORDER BY tablename, indexname;
