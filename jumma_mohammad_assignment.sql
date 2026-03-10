
-- Part B — SQL Setup (Required)
select order_id, customer_id, customer_name , city , product_name, unit_price , quantity ,line_amount, sum(unit_price * quantity) as total_amount
from uk_retail_raw
where order_status = 'completed'
group by order_id, customer_id, customer_name , city , product_name, unit_price , quantity , line_amount
order by total_amount desc 
limit 20;

SELECT
    order_id,
    product_name,
    line_amount,
    ROUND(unit_price * quantity, 2) AS calculated_amount,
    ROUND(line_amount - (unit_price * quantity), 2) AS difference
FROM uk_retail_raw
WHERE ROUND(line_amount, 2) <> ROUND(unit_price * quantity, 2);



SELECT *
FROM uk_retail_raw
WHERE (order_id, product_id) IN (
    SELECT order_id, product_id
    FROM uk_retail_raw
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
);




-- check null values 
SELECT *
FROM uk_retail_raw
WHERE customer_name IS NULL
   OR city IS NULL
   OR product_name IS NULL;


SELECT
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS customer_id_not_null,
    COUNT(customer_name) AS customer_name_not_null,
    COUNT(city) AS city_not_null,
    COUNT(product_name) AS product_not_null
FROM uk_retail_raw;


-- check of bad casting 
SELECT DISTINCT city
FROM uk_retail_raw
ORDER BY city;

-- check extra spaces
SELECT DISTINCT city
FROM uk_retail_raw
WHERE city LIKE ' %'
   OR city LIKE '% ';
   
-- create view 
CREATE VIEW clean_uk_retail AS
SELECT
  order_id,
  order_date,
  LOWER(TRIM(order_status)) AS order_status,
  shipping_days,

  customer_id,
  TRIM(customer_name) AS customer_name,
  LOWER(TRIM(email)) AS email,

  TRIM(region) AS region,
  COALESCE(TRIM(city),'Unknown') AS city,
  LOWER(TRIM(tier)) AS tier,

  signup_date,

  product_id,
  TRIM(product_name) AS product_name,
  LOWER(TRIM(category)) AS category,

  unit_price,
  quantity,
  line_amount,

  LOWER(TRIM(payment_method)) AS payment_method,
  LOWER(TRIM(acquisition_channel)) AS acquisition_channel,

  refund_id,
  refund_date,
  COALESCE(refund_amount,0) AS refund_amount,
  LOWER(TRIM(refund_reason)) AS refund_reason

FROM uk_retail_raw;


select * from clean_uk_retail;


-- Total Revenue
SELECT ROUND(SUM(line_amount),2) AS total_revenue
FROM clean_uk_retail
WHERE order_status = 'completed';


-- REFUND RATE 

SELECT
ROUND(SUM(refund_amount)/SUM(line_amount)*100,2) AS refund_rate
FROM clean_uk_retail;


-- ORDERS BY REGION
SELECT region,
COUNT(DISTINCT order_id) AS orders
FROM clean_uk_retail
GROUP BY region
ORDER BY orders DESC;

SELECT
    COUNT(DISTINCT order_id) AS total_orders,

    SUM(unit_price * quantity) AS gross_revenue,

    COALESCE(SUM(refund_amount), 0) AS total_refunds,

    SUM(unit_price * quantity)
      - COALESCE(SUM(refund_amount), 0) AS net_revenue

FROM clean_uk_retail
WHERE order_status = 'completed';


select *
from clean_uk_retail
where order_status= 'completed';

-- Part C — SQL Tasks 
-- C1) Exploration: Show 20 most recent order items (ORDER BY order_date DESC, LIMIT 20).
select *
from uk_retail_raw
order by order_date desc
limit 20;

-- 7.	C2) Unique customers: How many distinct customers placed at least one order in 2024? (Hint: DISTINCT customer_id; filter order_date in 2024.)
select count(distinct customer_id) as unique_customers_2024
from uk_retail_raw
where order_date >= '2024-01-01'
	and order_date< '2025-01-01';

-- 8.	C3) Revenue basics: Total completed revenue in 2024 (sum line_amount where order_status='Completed').
select sum(line_amount) as total_completed_revenue
from uk_retail_raw
where order_status='completed'
and order_date>='2024-01-01'
and order_date < '2025-01-01';

-- 9.	C4) AOV (Average Order Value): For completed orders in 2024, 
-- compute AOV = total revenue / number of distinct completed orders. 
SELECT
      SUM(unit_price * quantity) / COUNT(DISTINCT order_id) AS AOV_2024
FROM uk_retail_raw
WHERE order_status = 'completed'
  AND order_date >= '2024-01-01'
  AND order_date <  '2025-01-01';
  

  
-- 10.	C5) Top customers: Top 10 customers by completed revenue in 2024, with customer_name, region, tier.
  
SELECT CUSTOMER_NAME, REGION, TIER , order_status, ROUND(SUM(unit_price * quantity), 2) AS total_revenue
  FROM uk_retail_raw
  WHERE order_status = 'completed'
  AND order_date >= '2024-01-01'
  AND order_date <  '2025-01-01'
  GROUP BY CUSTOMER_NAME, REGION, TIER , order_status
  order by TOTAL_REVENUE DESC 
  LIMIT 10;
  
-- 11.	C6) Region performance: For each region, return completed orders (distinct order_id), revenue, and AOV. Sort by revenue DESC.
SELECT 
    region,
    COUNT(DISTINCT order_id) AS completed_orders,
    ROUND(SUM( order_total), 2) AS total_revenue,
    ROUND(AVG(order_total), 2) AS AOV
FROM (
    SELECT 
        region, 
        order_id, 
        SUM(unit_price * quantity) AS order_total
    FROM uk_retail_raw
    WHERE order_status = 'completed'
    GROUP BY region, order_id
) AS orders_per_order
GROUP BY region
ORDER BY total_revenue DESC;

-- 12.	C7) Tier performance: Compare Premium vs Standard: customers, completed orders, revenue, AOV, 
-- and % customers who purchased (customers with >=1 completed order).

select tier, 
COUNT(DISTINCT CUSTOMER_ID) AS Customers, 
count(distinct case when order_status='completed' then order_id end) as completed_orders, 
round(sum(case when order_status ='completed' then line_amount end),2) as revenue, 
round(sum(case when order_status='completed' then line_amount end)/ count(distinct case when order_status='completed' then order_id end) ,2) as AOV,
concat(round(count(distinct case when order_status='completed' then customer_id end) *100/ count(distinct customer_id),2),'%') as pct_customers_purchased
from uk_retail_raw
group by tier;


-- 13.	C8) Channel analysis: 
-- For each acquisition_channel, show customers acquired, 
-- completed revenue, refund_amount, and net_revenue (revenue - refunds).

SELECT
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS customers_acquired,
    ROUND(SUM(line_amount),2) AS completed_revenue,
    ROUND(SUM(refund_amount),2) AS refund_amount,
    ROUND(SUM(line_amount) - SUM(refund_amount),2) AS net_revenue
FROM uk_retail_raw
WHERE order_status = 'completed'
GROUP BY acquisition_channel
ORDER BY net_revenue DESC;




-- 14.	C9) Product category: 
-- For each category, show revenue, refunds, and refund_rate = refunds / revenue.
--  Return only categories with revenue > 5000 (HAVING).

SELECT category,round(sum(line_amount),2) as revenue, 
	round(sum(refund_amount),2) as refunded,
    concat(round(sum(refund_amount)/sum(line_amount) *100,2) ,'%') as refund_rate 
FROM uk_retail_raw
group by category
having sum(line_amount) >5000
order by revenue desc;

-- 15.	C10) Delivery delays: List the top 20 completed orders with shipping_days > 5, 
-- including customer_name, region, tier, order_date, shipping_days, order value (per order).
SELECT
    order_id,
    customer_name,
    region,
    tier,
    order_date,
    shipping_days,
    ROUND(SUM(line_amount),2) AS order_value
FROM uk_retail_raw
WHERE order_status = 'completed'
AND shipping_days > 5
GROUP BY 
    order_id,
    customer_name,
    region,
    tier,
    order_date,
    shipping_days
ORDER BY shipping_days DESC
LIMIT 20;


-- Part D — Analyst Skill: Normalise the Raw Data (SQL Modelling)
-- 1️ Customers Table (1 row per customer)
CREATE TABLE customers AS
SELECT
    customer_id,
    MAX(customer_name) AS customer_name,
    MAX(email) AS email,
    MAX(region) AS region,
    MAX(city) AS city,
    MAX(tier) AS tier,
    MIN(signup_date) AS signup_date
FROM uk_retail_raw
GROUP BY customer_id;

-- VERIFY 
SELECT CUSTOMER_ID, COUNT(*) 
FROM CUSTOMERS 
GROUP BY CUSTOMER_ID
HAVING COUNT(*) >1 ;


-- Products Table (1 row per product_id)
CREATE TABLE products AS
SELECT
    product_id,
    MAX(product_name) AS product_name,
    MAX(category) AS category,
    MAX(unit_price) AS unit_price
FROM uk_retail_raw
GROUP BY product_id;

-- VERIFY 
SELECT PRODUCT_ID , COUNT(*) 
FROM PRODUCTS 
GROUP BY PRODUCT_ID 
HAVING COUNT(*)>1;


-- 3. ORDERS TABLE 
CREATE TABLE orders AS
SELECT
    order_id,
    MIN(order_date) AS order_date,
    MAX(order_status) AS order_status,
    MAX(shipping_days) AS shipping_days,
    MAX(customer_id) AS customer_id,
    MAX(payment_method) AS payment_method,
    MAX(acquisition_channel) AS acquisition_channel
FROM uk_retail_raw
GROUP BY order_id;

-- VERIFY
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- ORDER_ITEMS TABLE 
CREATE TABLE order_items AS
SELECT
    order_id,
    product_id,
    SUM(quantity) AS quantity,
    SUM(line_amount) AS line_amount
FROM uk_retail_raw
GROUP BY order_id, product_id;

SELECT * FROM order_items;


-- Refunds Table (1 row per refund_id)
CREATE TABLE refunds AS
SELECT
    refund_id,
    MAX(order_id) AS order_id,
    MAX(product_id) AS product_id,
    MAX(refund_date) AS refund_date,
    CAST(MAX(refund_amount) AS DOUBLE) AS refund_amount,
    MAX(refund_reason) AS refund_reason
FROM uk_retail_raw
WHERE refund_id IS NOT NULL
GROUP BY refund_id;

-- VERIFY 
SELECT refund_id, COUNT(*)
FROM refunds
GROUP BY refund_id
HAVING COUNT(*) > 1;


-- Revenue Validation Check
SELECT ROUND(SUM(line_amount),2) AS raw_revenue
FROM uk_retail_raw
WHERE order_status = 'completed';

-- Revenue from Normalised Tables
SELECT ROUND(SUM(oi.line_amount),2) AS normalized_revenue
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id
WHERE o.order_status = 'completed';

-- Part E — Stretch 
-- 16.	E1) Cohort: By signup_month (YYYY-MM), show number of customers and their completed revenue in the first 90 days after signup.
SELECT date_format(C.SIGNUP_DATE, '%Y-%m') AS SIGNUP_MONTH,
COUNT(DISTINCT C.CUSTOMER_ID) AS CUSTOMERS,
ROUND(SUM(CASE 
			WHEN O.ORDER_STATUS='COMPLETED'
            AND O.ORDER_DATE BETWEEN C.SIGNUP_DATE
            AND DATE_ADD(C.SIGNUP_DATE, INTERVAL 90 DAY)
            THEN OI.LINE_AMOUNT 
            ELSE 0
		END),2) AS REVENUE_FIRST_90DAYS
FROM CUSTOMERS c 
LEFT JOIN ORDERS O 
ON C.customer_id = O.customer_id

LEFT JOIN order_items OI 
ON OI.order_id= O.order_id

group by SIGNUP_MONTH 
ORDER BY SIGNUP_MONTH;

-- 17.	E2) Repeat rate: % of customers with 2+ distinct completed orders in 2024, by tier.
SELECT C.TIER ,
CONCAT(ROUND(COUNT(distinct CASE WHEN O.COMPLETED_ORDERS >=2 THEN  C.customer_id END )*100.0
    / count(distinct C.customer_id)
    ,2),'%') AS REPEAT_RATE_PCT
	FROM customers C 
	LEFT JOIN 
    (SELECT 
    customer_id, 
    COUNT(DISTINCT ORDER_ID) AS COMPLETED_ORDERS 
    FROM ORDERS O 
    WHERE ORDER_STATUS='COMPLETED'
    AND str_to_date(ORDER_DATE,'%Y-%m-%d') between '2024-01-01' AND '2024-12-31' 
	GROUP BY customer_id ) o
	ON C.customer_id= O.customer_id
	group by C.TIER 
	ORDER BY C.TIER;


-- 18.	E3) “Refund risk”: Identify customers with refund_rate > 30% AND completed revenue > £300 in 2024.

WITH customer_revenue AS (
    -- Total completed revenue per customer in 2024
    SELECT
        customer_id,
        customer_name,
        tier,
        SUM(line_amount) AS completed_revenue
    FROM uk_retail_raw
    WHERE order_status = 'completed'
      AND STR_TO_DATE(order_date, '%Y-%m-%d') BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY customer_id, customer_name, tier
),
customer_refunds AS (
    -- Total refunds per customer in 2024
    SELECT
        customer_id,
        SUM(CAST(refund_amount AS DOUBLE)) AS total_refunds
    FROM uk_retail_raw
    WHERE refund_id IS NOT NULL
      AND STR_TO_DATE(order_date, '%Y-%m-%d') BETWEEN '2024-01-01' AND '2024-12-31'
    GROUP BY customer_id
)

SELECT
    cr.customer_id,
    cr.customer_name,
    cr.tier,
    cr.completed_revenue,
    COALESCE(rf.total_refunds,0) AS total_refunds,
    ROUND(COALESCE(rf.total_refunds,0)/cr.completed_revenue*100,2) AS refund_rate_pct
FROM customer_revenue cr
LEFT JOIN customer_refunds rf
    ON cr.customer_id = rf.customer_id
WHERE cr.completed_revenue > 300
  AND COALESCE(rf.total_refunds,0)/cr.completed_revenue > 0.3
ORDER BY refund_rate_pct DESC;