# SQL Retail Sales Analysis

Portfolio SQL project analyzing UK retail transaction data to answer practical business questions about revenue, refunds, customer behavior, product performance, delivery delays, and acquisition channels.

The project started as an assignment submission and has been reorganized into a clearer analytics workflow for portfolio review.

## Project Highlights

- Built a cleaned SQL view from raw retail transactions.
- Checked data quality issues such as nulls, duplicate order lines, inconsistent text casing, extra whitespace, and line amount mismatches.
- Calculated core KPIs including completed revenue, average order value, refund rate, net revenue, and repeat purchase rate.
- Compared performance by region, customer tier, product category, payment method, and acquisition channel.
- Modeled the raw data into customers, products, orders, order_items, and refunds tables.
- Added advanced analysis for cohorts, refund risk, monthly trends, and product category affinity.

## Dataset

The analysis expects a raw table called `uk_retail_raw` with transaction-level retail data.

Key fields used:

- `order_id`, `order_date`, `order_status`, `shipping_days`
- `customer_id`, `customer_name`, `email`, `region`, `city`, `tier`, `signup_date`
- `product_id`, `product_name`, `category`, `unit_price`, `quantity`, `line_amount`
- `payment_method`, `acquisition_channel`
- `refund_id`, `refund_date`, `refund_amount`, `refund_reason`

## Tools And SQL Dialect

- SQL
- MySQL 8.0 style syntax
- Common table expressions
- Aggregations and grouped business KPIs
- Data cleaning with `TRIM`, `LOWER`, `COALESCE`, `CAST`, and date functions

## Repository Structure

```text
.
|-- README.md
|-- jumma_mohammad_assignment.sql
|-- jumma_mohammad_assignment.pdf
|-- jumma_mohammad_assignment.zip
|-- docs/
|   `-- project_structure_review.md
`-- sql/
    |-- 01_data_quality_and_cleaning.sql
    |-- 02_business_analysis.sql
    |-- 03_data_modeling.sql
    `-- 04_advanced_analysis.sql
```

## How To Use

1. Load the retail dataset into a MySQL database as `uk_retail_raw`.
2. Run `sql/01_data_quality_and_cleaning.sql` to inspect the raw data and create `clean_uk_retail`.
3. Run `sql/02_business_analysis.sql` for core business KPIs.
4. Run `sql/03_data_modeling.sql` to create normalized tables.
5. Run `sql/04_advanced_analysis.sql` for cohort, repeat-rate, refund-risk, trend, and basket-style analysis.

The original submitted SQL is preserved in `jumma_mohammad_assignment.sql`.

## Business Questions Answered

- What is total completed revenue and average order value?
- Which regions and customer tiers drive the most revenue?
- Which acquisition channels generate the strongest net revenue?
- Which categories have high refund rates?
- Which completed orders experienced delivery delays?
- What percentage of customers make repeat purchases?
- Which customers show elevated refund risk?
- How does monthly completed revenue trend over time?
- Which product categories are commonly purchased together?

## Example Query

```sql
SELECT
    region,
    COUNT(DISTINCT order_id) AS completed_orders,
    ROUND(SUM(line_amount), 2) AS completed_revenue,
    ROUND(SUM(line_amount) / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS average_order_value
FROM clean_uk_retail
WHERE order_status = 'completed'
GROUP BY region
ORDER BY completed_revenue DESC;
```

## Key Skills Demonstrated

- SQL data cleaning
- KPI development
- Business question translation
- Customer and product analysis
- Refund and revenue analysis
- Normalized data modeling
- Portfolio-ready documentation
