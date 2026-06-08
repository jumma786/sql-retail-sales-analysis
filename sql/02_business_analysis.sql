/*
  SQL Retail Sales Analysis
  Step 02: Core business KPI analysis

  Run after sql/01_data_quality_and_cleaning.sql.
*/

-- 1. Total completed revenue, completed orders, AOV, refunds, and net revenue.
WITH completed_sales AS (
    SELECT
        COUNT(DISTINCT order_id) AS completed_orders,
        ROUND(SUM(line_amount), 2) AS completed_revenue
    FROM clean_uk_retail
    WHERE order_status = 'completed'
),
refunds AS (
    SELECT
        ROUND(SUM(refund_amount), 2) AS total_refunds
    FROM clean_uk_retail
)
SELECT
    completed_orders,
    completed_revenue,
    ROUND(completed_revenue / NULLIF(completed_orders, 0), 2) AS average_order_value,
    total_refunds,
    ROUND(completed_revenue - total_refunds, 2) AS net_revenue,
    ROUND(total_refunds / NULLIF(completed_revenue, 0) * 100, 2) AS refund_rate_pct
FROM completed_sales
CROSS JOIN refunds;

-- 2. Region performance.
SELECT
    region,
    COUNT(DISTINCT order_id) AS completed_orders,
    ROUND(SUM(line_amount), 2) AS completed_revenue,
    ROUND(SUM(line_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM clean_uk_retail
WHERE order_status = 'completed'
GROUP BY region
ORDER BY completed_revenue DESC;

-- 3. Top 10 customers by completed revenue.
SELECT
    customer_id,
    customer_name,
    region,
    tier,
    COUNT(DISTINCT order_id) AS completed_orders,
    ROUND(SUM(line_amount), 2) AS completed_revenue
FROM clean_uk_retail
WHERE order_status = 'completed'
GROUP BY customer_id, customer_name, region, tier
ORDER BY completed_revenue DESC
LIMIT 10;

-- 4. Customer tier performance.
SELECT
    tier,
    COUNT(DISTINCT customer_id) AS total_customers,
    COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN customer_id END) AS purchasing_customers,
    COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END) AS completed_orders,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END), 2) AS completed_revenue,
    ROUND(
        SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END)
        / NULLIF(COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END), 0),
        2
    ) AS average_order_value,
    ROUND(
        COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN customer_id END)
        / NULLIF(COUNT(DISTINCT customer_id), 0) * 100,
        2
    ) AS pct_customers_purchased
FROM clean_uk_retail
GROUP BY tier
ORDER BY completed_revenue DESC;

-- 5. Acquisition channel performance.
SELECT
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS customers_acquired,
    COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END) AS completed_orders,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END), 2) AS completed_revenue,
    ROUND(SUM(refund_amount), 2) AS refund_amount,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END) - SUM(refund_amount), 2) AS net_revenue
FROM clean_uk_retail
GROUP BY acquisition_channel
ORDER BY net_revenue DESC;

-- 6. Product category performance and refund rate.
SELECT
    category,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END), 2) AS completed_revenue,
    ROUND(SUM(refund_amount), 2) AS refund_amount,
    ROUND(
        SUM(refund_amount)
        / NULLIF(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END), 0) * 100,
        2
    ) AS refund_rate_pct
FROM clean_uk_retail
GROUP BY category
HAVING completed_revenue > 5000
ORDER BY completed_revenue DESC;

-- 7. Payment method performance.
SELECT
    payment_method,
    COUNT(DISTINCT CASE WHEN order_status = 'completed' THEN order_id END) AS completed_orders,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END), 2) AS completed_revenue,
    ROUND(SUM(refund_amount), 2) AS refund_amount,
    ROUND(SUM(CASE WHEN order_status = 'completed' THEN line_amount ELSE 0 END) - SUM(refund_amount), 2) AS net_revenue
FROM clean_uk_retail
GROUP BY payment_method
ORDER BY net_revenue DESC;

-- 8. Delivery delay analysis.
SELECT
    order_id,
    customer_name,
    region,
    tier,
    order_date,
    shipping_days,
    ROUND(SUM(line_amount), 2) AS order_value
FROM clean_uk_retail
WHERE order_status = 'completed'
  AND shipping_days > 5
GROUP BY order_id, customer_name, region, tier, order_date, shipping_days
ORDER BY shipping_days DESC, order_value DESC
LIMIT 20;
