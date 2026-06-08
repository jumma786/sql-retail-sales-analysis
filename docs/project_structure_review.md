# Project Structure Review

## Current State

The original repository contained the assignment SQL file, a PDF, a ZIP archive, and a short README. The SQL work was useful, but the project was difficult to scan quickly because the analysis, cleaning checks, modeling steps, and advanced tasks all lived in one script.

## Improvements Added

- Preserved the original assignment file for authenticity.
- Added a dedicated `sql/` folder with numbered scripts that follow the analysis workflow.
- Rewrote the README to explain the business problem, dataset shape, SQL dialect, structure, and key skills.
- Added safer KPI patterns using `NULLIF` to avoid divide-by-zero errors.
- Standardized analysis around `clean_uk_retail` so casing, spacing, and null handling are applied consistently.
- Added portfolio-friendly advanced queries for monthly trends, repeat rate, cohort revenue, refund risk, and category affinity.

## Suggested Future Enhancements

- Add the raw CSV or a small anonymized sample dataset if sharing is allowed.
- Add a schema diagram showing how customers, products, orders, order_items, and refunds relate.
- Add exported result screenshots or small result tables for the main business questions.
- Add a short findings section after running the queries against the dataset.
