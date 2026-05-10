--ANALYSIS FOR TRADEZONE

USE tradeZone;

SELECT * FROM customers
WHERE email IS NULL;
--Not dropping the rows with null values in the email column because the email is not crucial to the analysis

SELECT * FROM order_items
WHERE unit_price IS NULL
OR
line_total IS NULL;

SELECT * FROM products
WHERE unit_price IS NULL;

/*In the order_items table, there are null values in the unit_price and line_total colums
so I will use an innerjoin on the product table to fill in the null values in the order_items table.*/

UPDATE oi
SET oi.unit_price = COALESCE(o.unit_price, p.unit_price)
FROM order_items oi
INNER JOIN products p
	ON oi.product_id = p.product_id
WHERE oi.unit_price IS NULL
	AND p.unit_price IS NOT NULL;

--Since the unit_price I was trying to update in the order_items table is also null in the products table, I am deleting the products.

--I would first delete them from the order items table since it is a child table.

DELETE oi
FROM order_items oi
WHERE oi.unit_price IS NULL;

--I will also delete these products in the reviews table since it is also a child table.

DELETE r
FROM reviews r
INNER JOIN products p 
ON r.product_id = p.product_id
WHERE p.unit_price IS NULL;

--I would now delete it from the parent table which is products.
DELETE p
FROM products p
WHERE p.unit_price IS NULL;


--Changing the format of the city column in the customer table so it can have a regular format all through.
UPDATE customers
SET city = TRIM(LOWER(city));

--showing all the cities listed
SELECT city
FROM customers
GROUP BY city;

UPDATE customers
SET city =
CASE
	WHEN city IN ('lagos','lago s') THEN 'Lagos'
	WHEN city IN ('ibadan') THEN 'Ibadan'
	WHEN city IN ('port-harcourt', 'port harcourt', 'portharcourt') THEN 'Port Harcourt'
	WHEN city IN ('kano') THEN 'Kano'
	WHEN city IN ('abuja') THEN 'Abuja'
	ELSE city
END;

--ensuring consistency in the city column in the sellers table
UPDATE sellers
SET city = TRIM(LOWER(city));

--Showing all cities involved
SELECT city
FROM sellers
GROUP BY city;

UPDATE sellers
SET city =
CASE
	WHEN city IN ('abuja') THEN 'Abuja'
	WHEN city IN ('ibadan') THEN 'Ibadan'
	WHEN city IN ('lago s', 'lagos') THEN 'Lagos'
	WHEN city IN ('kano') THEN 'Kano'
	WHEN city IN ('port harcourt','port-harcourt','portharcourt') THEN 'Port Harcourt'
	ELSE city
END;

SELECT product_category
FROM sellers
GROUP BY product_category;

--Ensuring that the product_category colum in the sellers table is consistent
UPDATE sellers
SET product_category = TRIM(LOWER(product_category));

UPDATE sellers
SET product_category =
CASE
	WHEN product_category IN ('ELECTRONICS','electronics','electronis') THEN 'Electronics'
	WHEN product_category IN ('beauty & personal care','beauty and personal care','beauty') THEN 'Beauty and Personal Care'
	WHEN product_category IN ('books', 'books & stationery','books and stationery') THEN 'Books and Stationery'
	WHEN product_category IN ('fashion','fashon') THEN 'Fashion'
	WHEN product_category IN ('food','food & beverages','food and beverages') THEN 'Food and Beverages'
	WHEN product_category IN ('home & garden','home and garden') THEN 'Home and Garden'
	WHEN product_category IN ('sports','sports & fitness','sports and fitness') THEN 'Sports and Fitness'
	ELSE product_category
END;

--Ensuring that the category colum in the products table is consistent
SELECT category
FROM products
GROUP BY category;

UPDATE products
SET category = TRIM(LOWER(category));

UPDATE products
SET category =
CASE
	WHEN category IN ('ELECTRONICS','electronics','electronis') THEN 'Electronics'
	WHEN category IN ('beauty & personal care','beauty and personal care','beauty') THEN 'Beauty and Personal Care'
	WHEN category IN ('books', 'books & stationery','books and stationery') THEN 'Books and Stationery'
	WHEN category IN ('fashion','fashon') THEN 'Fashion'
	WHEN category IN ('food','food & beverages','food and beverages') THEN 'Food and Beverages'
	WHEN category IN ('home & garden','home and garden') THEN 'Home and Garden'
	WHEN category IN ('sports','sports & fitness','sports and fitness') THEN 'Sports and Fitness'
	ELSE category
END;

SELECT * FROM customers WHERE email IS NULL;

--Checking for duplicates in the customer table
SELECT customer_id, COUNT(*) AS customer_count
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

--Checking for duplicates in the order table
SELECT order_id, COUNT(*) AS order_count
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

--Checking for duplicates in the sellers table
SELECT seller_id, COUNT(*) AS seller_count
FROM sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

--Checking if all dates have consistent formats
SELECT signup_date
FROM customers;

SELECT order_date, delivery_date
FROM orders;

SELECT payment_date 
FROM payments;

SELECT review_date
FROM reviews;

--Verifying that each order's total_amount matches the sum of its line items in order_items
SELECT o.order_id,
	o.total_amount,
	SUM(oi.line_total) AS computed_total
FROM orders o
JOIN order_items oi
ON o.order_id = oi.order_id
WHERE o.total_amount IS NULL
GROUP BY o.order_id, o.total_amount

SELECT *
FROM order_items
WHERE line_total IS NULL;

--Filling the rows whit null total_amounts using line_total
UPDATE o
SET o.total_amount = s.total
FROM orders o
INNER JOIN (
    SELECT order_id, SUM(line_total) AS total
    FROM order_items
    GROUP BY order_id
) s ON o.order_id = s.order_id
WHERE o.total_amount IS NULL;

--Validating order totals
SELECT 
    o.order_id,
    o.total_amount,
    SUM(oi.line_total) AS computed_total,
    ABS(o.total_amount - SUM(oi.line_total)) AS difference
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.total_amount
HAVING ABS(o.total_amount - SUM(oi.line_total)) > 10;


--validating ratings
SELECT * 
FROM reviews
WHERE rating NOT BETWEEN 1 AND 5;

--Checking prices
SELECT * FROM products WHERE unit_price < 0;

--Removing rows with invalid ratings
DELETE r 
FROM reviews r
WHERE rating NOT BETWEEN 1 AND 5;