/*Question 1: Customer Acquisition & 30-Day Conversion
Find the top 5 states by number of new customer sign-ups in 2024. 
For each state, calculate what percentage of these new customers made at least one purchase within their first 30 days of signing up.
*/

SELECT TOP 5
        c.state,
		COUNT(DISTINCT c.customer_id) AS new_customers,
		COUNT(CASE WHEN o.order_id IS NOT NULL THEN 1 END) * 100.0/COUNT(*) AS conversion_rate
FROM customers c
LEFT JOIN orders o
	ON c.customer_id=o.customer_id
    AND DATEADD(DAY, 30, c.signup_date) >= o.order_date
WHERE YEAR(c.signup_date) =2024
GROUP BY c.state
ORDER BY new_customers desc;

/*Question 2: Product Performance
Identify the top 10 products by total revenue in 2024. 
Include product name, category, total revenue and total number of orders. 
Sort by revenue descending.
*/

SELECT TOP 10
		p.product_name,
		p.category,
		SUM(o.total_amount) as total_revenue,
		COUNT(o.order_id) AS order_count
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
JOIN orders o
ON oi.order_id=o.order_id
WHERE YEAR(o.order_date) = 2024
GROUP BY p.product_name, p.category
ORDER BY total_revenue desc;

SELECT 
		p.category,
		SUM(o.total_amount) as total_revenue
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
JOIN orders o
ON oi.order_id=o.order_id

GROUP BY p.category
ORDER BY total_revenue desc;

/*Question 3: Seller Fulfilment Efficiency
Calculate the average time in hours between order placement and delivery for each seller.
Return the top 20 sellers with the fastest average fulfilment times among sellers who have completed at least 20 orders. 
Include their total completed orders and average customer rating.
*/

SELECT TOP 20 
		s.seller_id,
		s.seller_name,
		AVG(DATEDIFF(HOUR, order_date, delivery_date)) AS fulfillment_hours,
		COUNT(o.order_id) AS order_count,
		AVG(r.rating) AS average_rating
FROM sellers s
JOIN orders o
ON s.seller_id = o.seller_id
LEFT JOIN reviews r
ON o.order_id = r.order_id
GROUP BY s.seller_id, s.seller_name
HAVING COUNT(o.order_id)>=20
ORDER BY fulfillment_hours ASC;




/*Question 4: Quarterly Revenue Trends
Compare quarterly revenue across 2023 and 2024. 
For each quarter, calculate total revenue, average order value and total number of orders. 
Identify which single quarter showed the strongest revenue growth from 2023 to 2024.
*/
SELECT YEAR(order_date) AS Year,
		DATEPART(QUARTER, order_date) AS quarter,
		SUM(total_amount) AS total_revenue,
		AVG(total_amount) AS avg_order_value,
		COUNT(*) AS order_count
FROM orders
WHERE YEAR(order_date) IN (2023,2024)
GROUP BY YEAR(order_date), DATEPART(QUARTER, order_date)
ORDER BY Year, quarter;

/*Question 5: Customer Spend Segmentation
Segment customers based on their total spend in 2024 into three groups:

 High Spenders: ≥ ₦100,000
 Medium Spenders: ₦50,000 – ₦99,999
Low Spenders: < ₦50,000
For each group, calculate the customer count, average spend per customer and total revenue contribution.
*/

WITH customer_spend AS (
    SELECT 
        c.customer_id,
        SUM(o.total_amount) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    WHERE YEAR(o.order_date) = 2024
    GROUP BY c.customer_id
)

SELECT 
    CASE 
        WHEN total_spend >= 100000 THEN 'High Spenders'
        WHEN total_spend BETWEEN 50000 AND 99999 THEN 'Medium Spenders'
        ELSE 'Low Spenders'
    END AS segment,
    COUNT(*) AS customer_count,
    AVG(total_spend) AS avg_spend,
    SUM(total_spend) AS total_revenue
FROM customer_spend
GROUP BY 
    CASE 
        WHEN total_spend >= 100000 THEN 'High Spenders'
        WHEN total_spend BETWEEN 50000 AND 99999 THEN 'Medium Spenders'
        ELSE 'Low Spenders'
    END;

/*Question 6: Payment Method Preferences by State
Analyse payment method preferences across each state in the dataset. 
For each state, show the transaction count and total amount for each payment method (Cash on Delivery, Card, Mobile Money, Bank Transfer) and identify the most popular method per state.
*/

SELECT c.state,
        payment_method,
        COUNT(p.payment_method) AS method_count,
        SUM(p.amount) AS total_amount
FROM payments p
JOIN orders o 
    ON p.order_id = o.order_id
JOIN customers c 
    ON o.customer_id = c.customer_id
GROUP BY c.state, p.payment_method
ORDER BY c.state;

/*Question 7: Review Ratings and Sales Performance
Group products based on their average review rating into three categories:

High Rated: 4.0 and above
Mid Rated: 3.0 – 3.99
Low Rated: Below 3.0
For each category, calculate the product count, total revenue and average unit price.
*/


WITH product_ratings AS (
    SELECT 
        p.seller_id,
        p.product_id,
        p.product_name,
        p.unit_price,
        AVG(r.rating) AS avg_rating,
        SUM(oi.line_total) AS total_revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN reviews r ON oi.order_id = r.order_id
    GROUP BY p.seller_id, p.product_id, p.product_name, p.unit_price
)

SELECT 
    CASE 
        WHEN avg_rating >= 4 THEN 'High Rated'
        WHEN avg_rating BETWEEN 3 AND 3.99 THEN 'Mid Rated'
        ELSE 'Low Rated'
    END AS rating_category,
    COUNT(product_id) AS product_count,
    SUM(total_revenue) AS total_revenue,
    AVG(unit_price) AS avg_unit_price
FROM product_ratings
GROUP BY 
    CASE 
        WHEN avg_rating >= 4 THEN 'High Rated'
        WHEN avg_rating BETWEEN 3 AND 3.99 THEN 'Mid Rated'
        ELSE 'Low Rated'
    END;

/*Question 8: Top Seller Bonus Qualification
Identify the top 10 sellers in 2024 by total revenue who completed at least 10 orders and have an average customer rating of 4.0 or above.
Include their total orders, average rating, and total revenue.
*/

SELECT TOP 10
    s.seller_id,
    COUNT(o.order_id) AS total_orders,
    AVG(r.rating) AS avg_rating,
    SUM(o.total_amount) AS total_revenue
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE YEAR(o.order_date) = 2024
GROUP BY s.seller_id
HAVING COUNT(o.order_id) >= 10
   AND AVG(r.rating) >= 4
ORDER BY total_revenue DESC;

SELECT TOP 15
    s.seller_id,
    s.state,
    COUNT(o.order_id) AS total_orders,
    AVG(r.rating) AS avg_rating,
    SUM(o.total_amount) AS total_revenue
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
LEFT JOIN reviews r ON o.order_id = r.order_id
WHERE YEAR(o.order_date) = 2024
GROUP BY s.seller_id, s.state
HAVING COUNT(o.order_id) >= 10
   AND AVG(r.rating) >= 4
ORDER BY total_revenue DESC;

SELECT c.state,
        o.order_status,
        COUNT(o.order_status) AS status_count
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
GROUP BY c.state, o.order_status
ORDER BY state, status_count desc;

SELECT state,
        COUNT(customer_id) AS cust_count
FROM customers
GROUP BY state;


SELECT 
        c.state,
        p.category,
        COUNT(o.order_id) AS order_count
FROM products p
JOIN order_items oi
ON p.product_id=oi.product_id
JOIN orders o
ON oi.order_id = o.order_id
JOIN customers c
ON o.customer_id=c.customer_id
GROUP BY c.state, p.category
ORDER BY c.state, order_count desc;


Select * FROM order_items
ORDER BY product_id;