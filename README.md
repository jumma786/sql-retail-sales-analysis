# 📊 UK Retail Data Analysis (SQL Project)

## Project Overview
This project analyzes a UK retail dataset using SQL to generate business insights related to revenue performance, customer behavior, refunds, and regional sales trends. The goal is to transform raw transactional data into meaningful insights that support data-driven decision making.

## Dataset
The dataset contains retail transaction data including:
- Customer information
- Order details
- Product information
- Order status (completed, refunded)
- Revenue and refund amounts
- Region and acquisition channel

## Tools Used
- SQL
- Data Cleaning Techniques
- Aggregations and Group By
- Business KPI Analysis

## Data Cleaning
The following data cleaning steps were performed:
- Removed leading and trailing spaces
- Standardized text formatting
- Checked for null values
- Identified duplicate records
- Created a cleaned dataset view for analysis

## Key Business Questions Answered
- What is the total completed revenue?
- What is the refund rate?
- Which regions generate the most revenue?
- What is the average order value?
- Which acquisition channels perform best?

## Example SQL Query

```sql
SELECT region,
SUM(line_amount) AS revenue
FROM clean_uk_retail
WHERE order_status = 'completed'
GROUP BY region
ORDER BY revenue DESC;
