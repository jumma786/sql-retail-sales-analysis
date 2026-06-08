/*
  SQL Retail Sales Analysis
  Step 04: Advanced portfolio analysis

  Run after sql/01_data_quality_and_cleaning.sql.
  Some queries use normalized tables created in sql/03_data_modeling.sql.
*/

-- 1. Monthly completed revenue, refunds, and net revenue.
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END) AS completed_orders,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END), 2) AS completed_revenue,
    ROUND(SUM(refund_amount), 2) AS refund_amount,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END) - SUM(refund_amount), 2) AS net_revenue
FROM clean_uk_retail
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- 2. Customer cohort revenue in the first 90 days after signup.
SELECT
    DATE_FORMAT(c.signup_date, '%Y-%m') AS signup_month,
    COUNT(DISTINCT c.customer_id) AS customers,
    ROUND(
        SUM(
            CASE
                WHEN o.order_status = 'completed'
                 AND o.order_date >= c.signup_date
                 AND o.order_date < DATE_ADD(c.signup_date, INTERVAL 90 DAY)
                THEN oi.line_amount
                ELSE 0
            END
        ),
        2
    ) AS completed_revenue_first_90_days
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id
LEFT JOIN order_items oi
  ON o.order_id = oi.order_id
GROUP BY DATE_FORMAT(c.signup_date, '%Y-%m')
ORDER BY signup_month;

-- 3. Repeat purchase rate by customer tier for 2024.
WITH completed_orders_2024 AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS completed_orders
    FROM orders
    WHERE order_status = 'completed'
      AND order_date >= '2024-01-01'
      AND order_date < '2025-01-01'
    GROUP BY customer_id
)
SELECT
    c.tier,
    COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT CASE WHEN co.completed_orders >= 2 THEN c.customer_id END) AS repeat_customers,
    ROUND(
        COUNT(DISTINCT CASE WHEN co.completed_orders >= 2 THEN c.customer_id END)
        / NULLIF(COUNT(DISTINCT c.customer_id), 0) * 100,
        2
    ) AS repeat_rate_pct
FROM customers c
LEFT JOIN completed_orders_2024 co
  ON c.customer_id = co.customer_id
GROUP BY c.tier
ORDER BY repeat_rate_pct DESC;

-- 4. Refund risk: customers with refund rate above 30% and completed revenue above 300 in 2024.
WITH customer_revenue AS (
    SELECT
        customer_id,
        customer_name,
        tier,
        ROUND(SUM(line_amount), 2) AS completed_revenue
    FROM clean_uk_retail
    WHERE order_status = 'completed'
      AND order_date >= '2024-01-01'
      AND order_date < '2025-01-01'
    GROUP BY customer_id, customer_name, tier
),
customer_refunds AS (
    SELECT
        customer_id,
        ROUND(SUM(refund_amount), 2) AS total_refunds
    FROM clean_uk_retail
    WHERE refund_id IS NOT NULL
      AND order_date >= '2024-01-01'
      AND order_date < '2025-01-01'
    GROUP BY customer_id
)
SELECT
    cr.customer_id,
    cr.customer_name,
    cr.tier,
    cr.completed_revenue,
    COALESCE(cf.total_refunds, 0) AS total_refunds,
    ROUND(COALESCE(cf.total_refunds, 0) / NULLIF(cr.completed_revenue, 0) * 100, 2) AS refund_rate_pct
FROM customer_revenue cr
LEFT JOIN customer_refunds cf
  ON cr.customer_id = cf.customer_id
WHERE cr.completed_revenue > 300
  AND COALESCE(cf.total_refunds, 0) / NULLIF(cr.completed_revenue, 0) > 0.30
ORDER BY refund_rate_pct DESC, completed_revenue DESC;

-- 5. Product category affinity: categories commonly purchased in the same completed order.
WITH order_categories AS (
    SELECT DISTINCT
        order_id,
        category
    FROM clean_uk_retail
    WHERE order_status = 'completed'
)
SELECT
    a.category AS category_a,
    b.category AS category_b,
    COUNT(*) AS shared_completed_orders
FROM order_categories a
JOIN order_categories b
  ON a.order_id = b.order_id
 AND a.category < b.category
GROUP BY a.category, b.category
ORDER BY shared_completed_orders DESC, category_a, category_b
LIMIT 20;

-- 6. High-value customers with late deliveries.
WITH order_values AS (
    SELECT
        order_id,
        customer_id,
        customer_name,
        region,
        tier,
        MAX(shipping_days) AS shipping_days,
        ROUND(SUM(line_amount), 2) AS order_value
    FROM clean_uk_retail
    WHERE order_status = 'completed'
    GROUP BY order_id, customer_id, customer_name, region, tier
)
SELECT
    customer_id,
    customer_name,
    region,
    tier,
    COUNT(*) AS delayed_orders,
    ROUND(SUM(order_value), 2) AS delayed_order_value
FROM order_values
WHERE shipping_days > 5
GROUP BY customer_id, customer_name, region, tier
ORDER BY delayed_order_value DESC
LIMIT 20;
