-- Monday Coffee -- Data Analysis 

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis


-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name,
    CAST((population * 0.25) / 1000000.0 AS DECIMAL(10,2))
        AS coffee_consumers_in_millions,
    city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;


-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?



SELECT 
    SUM(total) AS total_revenue
FROM sales
WHERE 
    YEAR(sale_date) = 2023
    AND DATEPART(QUARTER, sale_date) = 4;


-- City wise revenue
--Which cities generated the most revenue from coffee sales in Q4 (Oct–Dec) 2023?
SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN city ci
    ON ci.city_id = c.city_id
WHERE 
    YEAR(s.sale_date) = 2023
    AND DATEPART(QUARTER, s.sale_date) = 4
GROUP BY ci.city_name
ORDER BY total_revenue DESC;


-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
    p.product_name,
    COUNT(s.sale_id) AS total_units
FROM products p
LEFT JOIN sales s
    ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units DESC;

--left join because we want to see all the product names from product table even if they have not been sold

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- to find: city and total sale , total no. of customer in each these city


SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    CAST(
        SUM(s.total) * 1.0 / COUNT(DISTINCT s.customer_id)
        AS DECIMAL(10,2)
    ) AS avg_sale_pr_cx
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN city ci
    ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY avg_sale_pr_cx DESC;
-- * 1.0 forces decimals, CAST controls precision.



-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table AS (
    SELECT 
        city_id,
        city_name,
        CAST(
            ROUND((population * 0.25) / 1000000.0, 2)
            AS DECIMAL(10,2)
        ) AS coffee_consumers_in_millions
    FROM city
),
customers_table AS (
    SELECT 
        c.city_id,
        COUNT(DISTINCT c.customer_id) AS unique_cx
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    GROUP BY c.city_id
)
SELECT 
    ci.city_name,
    ct.coffee_consumers_in_millions,
    cust.unique_cx
FROM city_table ct
JOIN customers_table cust
    ON ct.city_id = cust.city_id
JOIN city ci
    ON ct.city_id = ci.city_id
ORDER BY coffee_consumers_in_millions DESC;




-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT *
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name
            ORDER BY COUNT(s.sale_id) DESC
        ) AS product_rank
    FROM sales s
    JOIN products p
        ON s.product_id = p.product_id
    JOIN customers c
        ON c.customer_id = s.customer_id
    JOIN city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) t
WHERE product_rank <= 3
ORDER BY city_name, product_rank;



-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?


SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) AS unique_cx
FROM sales s
JOIN customers c
    ON s.customer_id = c.customer_id
JOIN city ci
    ON c.city_id = ci.city_id
WHERE s.product_id IN (
    1, 2, 3, 4, 5, 6, 7,
    8, 9, 10, 11, 12, 13, 14
)
GROUP BY ci.city_name
ORDER BY unique_cx DESC;


-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_sales AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        CAST(
            SUM(s.total) * 1.0 / COUNT(DISTINCT s.customer_id)
            AS DECIMAL(10,2)
        ) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_id, ci.city_name
),
city_rent AS (
    SELECT 
        city_id,
        estimated_rent
    FROM city
)
SELECT 
    cs.city_name,
    cr.estimated_rent,
    cs.total_cx,
    cs.avg_sale_pr_cx,
    CAST(
        cr.estimated_rent * 1.0 / cs.total_cx
        AS DECIMAL(10,2)
    ) AS avg_rent_per_cx
FROM city_sales cs
JOIN city_rent cr
    ON cs.city_id = cr.city_id
ORDER BY cs.avg_sale_pr_cx DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city
-- Calculates month-over-month % change in sales for each city
-- Uses LAG() to compare current month with previous month
-- Q9: Monthly Sales Growth by City

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        YEAR(s.sale_date) AS year,
        MONTH(s.sale_date) AS month,
        SUM(s.total) AS total_sale
    FROM sales s
    JOIN customers c
        ON c.customer_id = s.customer_id
    JOIN city ci
        ON ci.city_id = c.city_id
    GROUP BY 
        ci.city_name,
        YEAR(s.sale_date),
        MONTH(s.sale_date)
),
growth_ratio AS (
    SELECT
        city_name,
        year,
        month,
        total_sale AS cr_month_sale,
        LAG(total_sale) OVER (
            PARTITION BY city_name
            ORDER BY year, month
        ) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    year,
    month,
    cr_month_sale,
    last_month_sale,
    CAST(
        (cr_month_sale - last_month_sale) * 100.0 / last_month_sale
        AS DECIMAL(10,2)
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;


-- Q10: Market Potential Analysis
-- Identifies top 3 cities based on sales, customers, rent, and market size

WITH city_sales AS (
    SELECT 
        ci.city_id,
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        CAST(
            SUM(s.total) * 1.0 / COUNT(DISTINCT s.customer_id)
            AS DECIMAL(10,2)
        ) AS avg_sale_pr_cx
    FROM sales s
    JOIN customers c
        ON s.customer_id = c.customer_id
    JOIN city ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_id, ci.city_name
),
city_market AS (
    SELECT 
        city_id,
        estimated_rent,
        CAST(
            (population * 0.25) / 1000000.0
            AS DECIMAL(10,2)
        ) AS estimated_coffee_consumer_millions
    FROM city
)
SELECT TOP 3
    cs.city_name,
    cs.total_revenue,
    cm.estimated_rent AS total_rent,
    cs.total_cx,
    cm.estimated_coffee_consumer_millions,
    cs.avg_sale_pr_cx,
    CAST(
        cm.estimated_rent * 1.0 / cs.total_cx
        AS DECIMAL(10,2)
    ) AS avg_rent_per_cx
FROM city_sales cs
JOIN city_market cm
    ON cs.city_id = cm.city_id
ORDER BY cs.total_revenue DESC;

/*
-- Recomendation
City 1: Pune
	1.Average rent per customer is very low.
	2.Highest total revenue.
	3.Average sales per customer is also high.

City 2: Delhi
	1.Highest estimated coffee consumers at 7.7 million.
	2.Highest total number of customers, which is 68.
	3.Average rent per customer is 330 (still under 500).

City 3: Jaipur
	1.Highest number of customers, which is 69.
	2.Average rent per customer is very low at 156.
	3.Average sales per customer is better at 11.6k.


