/* =========================================================
   PROJECT: Monday Coffee – Sanity Checks
   PURPOSE: Validate data quality after initial load
   AUTHOR: You
   ========================================================= */

USE MondayCoffee;
GO

/* ---------------------------------------------------------
   1. Row count check
   PURPOSE:
   - Ensure all tables loaded successfully
   - Detect partial or failed inserts
   EXPECTATION:
   - All counts > 0
   --------------------------------------------------------- */
SELECT 'city' AS table_name, COUNT(*) AS row_count FROM city
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'sales', COUNT(*) FROM sales;
GO

/* ---------------------------------------------------------
   2. NULL checks on critical columns
   PURPOSE:
   - NULLs in these columns break joins & aggregations
   EXPECTATION:
   - All values should be 0
   --------------------------------------------------------- */
SELECT
    SUM(CASE WHEN sale_id IS NULL THEN 1 ELSE 0 END) AS null_sale_id,
    SUM(CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END) AS null_sale_date,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN total IS NULL THEN 1 ELSE 0 END) AS null_total,
    SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END) AS null_rating
FROM sales;
GO

/* ---------------------------------------------------------
   3. Orphan record checks (foreign key sanity)
   PURPOSE:
   - Ensure referential integrity is intact
   - Detect broken relationships
   EXPECTATION:
   - All counts = 0
   --------------------------------------------------------- */

-- Customers without a valid city
SELECT COUNT(*) AS customers_without_city
FROM customers c
LEFT JOIN city ci
    ON c.city_id = ci.city_id
WHERE ci.city_id IS NULL;
GO

-- Sales without a valid customer
SELECT COUNT(*) AS sales_without_customer
FROM sales s
LEFT JOIN customers c
    ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
GO

-- Sales without a valid product
SELECT COUNT(*) AS sales_without_product
FROM sales s
LEFT JOIN products p
    ON s.product_id = p.product_id
WHERE p.product_id IS NULL;
GO

/* ---------------------------------------------------------
   4. Primary key duplication check
   PURPOSE:
   - Ensure no accidental double inserts
   - PK duplicates are critical data corruption
   EXPECTATION:
   - No rows returned
   --------------------------------------------------------- */
SELECT sale_id, COUNT(*) AS cnt
FROM sales
GROUP BY sale_id
HAVING COUNT(*) > 1;
GO

/* ---------------------------------------------------------
   5. Business-level duplicate check
   PURPOSE:
   - Detect duplicate product names with different IDs
   - Common real-world data issue
   EXPECTATION:
   - Either 0 rows or known/acceptable duplicates
   --------------------------------------------------------- */
SELECT product_name, COUNT(*) AS cnt
FROM products
GROUP BY product_name
HAVING COUNT(*) > 1;
GO

/* ---------------------------------------------------------
   6. Value sanity checks
   PURPOSE:
   - Ensure revenue calculations are meaningful
   - Detect negative or zero sales
   EXPECTATION:
   - invalid_sales = 0
   --------------------------------------------------------- */
SELECT
    SUM(CASE WHEN total <= 0 THEN 1 ELSE 0 END) AS invalid_sales
FROM sales;
GO

/* ---------------------------------------------------------
   7. Date range validation
   PURPOSE:
   - Understand time span of dataset
   - Catch incorrect or corrupted dates
   EXPECTATION:
   - Reasonable business date range
   --------------------------------------------------------- */
SELECT
    MIN(sale_date) AS first_sale_date,
    MAX(sale_date) AS last_sale_date
FROM sales;
GO

/* ---------------------------------------------------------
   8. Distribution sanity check
   PURPOSE:
   - Identify outliers early
   - Get a feel for data scale
   EXPECTATION:
   - Avg between min & max
   - No extreme unexpected values
   --------------------------------------------------------- */
SELECT
    COUNT(*) AS total_sales,
    AVG(total) AS avg_sale_value,
    MIN(total) AS min_sale_value,
    MAX(total) AS max_sale_value
FROM sales;
GO

/* ---------------------------------------------------------
   9. Dimension coverage checks
   PURPOSE:
   - Ensure dimensions are populated
   --------------------------------------------------------- */

-- Customers per city
SELECT
    ci.city_name,
    COUNT(c.customer_id) AS customer_count
FROM city ci
LEFT JOIN customers c
    ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY customer_count DESC;
GO

-- Sales per product
SELECT
    p.product_name,
    COUNT(s.sale_id) AS sales_count
FROM products p
LEFT JOIN sales s
    ON p.product_id = s.product_id
GROUP BY p.product_name
ORDER BY sales_count DESC;
GO

/* ---------------------------------------------------------
   END OF SANITY CHECKS
   If all checks pass:
   - Dataset is analysis-ready
   - Safe to proceed with joins & window functions
   --------------------------------------------------------- */
