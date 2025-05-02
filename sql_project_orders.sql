
-- Defining the table structure.
CREATE TABLE df_orders(
	order_id INT PRIMARY KEY,	
	order_date DATE,	
	ship_mode VARCHAR (20),	
	segment VARCHAR (20),	
	country VARCHAR (20),	
	city VARCHAR(20),	
	state VARCHAR(20),	
	postal_code VARCHAR(20),	
	region VARCHAR(20),	
	category VARCHAR(20),
	sub_category VARCHAR(20),	
	product_id	VARCHAR(50),
	quantity INT,	
	discount decimal (7,2),
	sale_price decimal (7,2),
	profit decimal (7,2)
)
SELECT TOP 0 * FROM df_orders;

-- 1. Find top 10 highest reveneue generating products.
SELECT TOP 10 product_id, SUM(quantity * sale_price) revenue_generated 
FROM df_orders 
GROUP BY product_id
ORDER BY revenue_generated DESC;

-- 2. Find top 5 highest selling products in each region.
WITH rev_gen AS(
SELECT region, product_id, SUM(quantity * sale_price) revenue_generated 
FROM df_orders 
GROUP BY region, product_id
)
SELECT * FROM
(SELECT *,
	ROW_NUMBER() OVER(PARTITION BY region ORDER BY revenue_generated DESC) AS rn
FROM rev_gen) mid WHERE rn <= 5;

-- 3. Find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023
WITH yr_mon_segmentation AS (
SELECT YEAR(order_date) AS order_year, MONTH(order_date) AS order_month,
SUM(quantity * sale_price) AS revenue_generated
FROM df_orders
GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT order_month,
	SUM(CASE WHEN order_year = 2022 THEN revenue_generated ELSE 0 END) AS revenue_for_2022,
	SUM(CASE WHEN order_year = 2023 THEN revenue_generated ELSE 0 END) AS revenue_for_2023
FROM yr_mon_segmentation
GROUP BY order_month
ORDER  BY order_month;

-- 4. For each category, the month with highest sales.
WITH sales_by_monthYEAR AS (
SELECT category, FORMAT(order_date, 'yyyy-MM') AS order_year_month,
	SUM(sale_price) AS sales
FROM df_orders
GROUP BY category, FORMAT(order_date, 'yyyy-MM')
)
SELECT *
FROM 
(SELECT *, ROW_NUMBER() OVER (PARTITION BY category ORDER BY sales DESC) AS rn FROM sales_by_monthYEAR) as rank
WHERE rn = 1
ORDER BY category;

-- 5. Which subcategory had the highest growth by profit in 2023 compared to 2022?
WITH profit_by_subcategory AS (
SELECT sub_category, YEAR(order_date) AS order_year,
SUM(profit) AS profit
FROM df_orders
GROUP BY sub_category, YEAR(order_date)
),
year_by_year_comparison AS (
SELECT sub_category,
	SUM(CASE WHEN order_year = 2022 THEN profit ELSE 0 END) AS profit_for_2022,
	SUM(CASE WHEN order_year = 2023 THEN profit ELSE 0 END) AS profit_for_2023
FROM profit_by_subcategory
GROUP BY sub_category
)
SELECT TOP 1 *, 
	(profit_for_2023-profit_for_2022)/profit_for_2022 * 100 AS growth_pct
FROM year_by_year_comparison
ORDER BY  growth_pct DESC;
 