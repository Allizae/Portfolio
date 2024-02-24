-- What are the quarterly trends for order count, sales and AOV, for Macbooks sold in North America across all years?
-- Double join between the orders, customers, and geo_lookup table
-- Use a CTE to get the average of the metrics
-- Group by 1 to see breakdown by quarter

WITH quarterly_trends AS (SELECT date_trunc(purchase_ts, quarter) as quarter,
  count (distinct orders.id) as total_orders, 
  round(sum(orders.usd_price),2) as total_sales, 
  round(avg(orders.usd_price),2) as aov
FROM core.orders
LEFT JOIN core.customers
ON orders.customer_id = customers.id
LEFT JOIN core.geo_lookup
ON customers.country_code= geo_lookup.country
WHERE orders.product_name LIKE 'Macbook%' AND geo_lookup.region = 'NA'
GROUP BY 1
ORDER BY 1 DESC, 2)

SELECT avg(total_orders) avg_orders,
  avg(total_sales) as avg_sales,
  avg(aov) as avg_aov
FROM quarterly_trends;

--For products purchased in 2022 on the website or products purchased on mobile in any year, which region has the highest time to deliver?
--Triple join between the orders_status table, orders table, customers table, and the geo_lookup table
--Group by 1 to see breakdown by region

SELECT geo_lookup.region as region,
  avg(date_diff(order_status.delivery_ts, order_status.purchase_ts, day)) as time_to_deliver
FROM core.order_status
LEFT JOIN core.orders 
ON order_status.order_id = orders.id
LEFT JOIN core.customers
ON customers.id = orders.customer_id
LEFT JOIN core.geo_lookup
ON geo_lookup.country = customers.country_code
WHERE (extract(year from orders.purchase_ts) = 2022 and orders.purchase_platform = 'website') OR orders.purchase_platform = 'mobile app'
GROUP BY 1
ORDER BY 2 DESC;

--Are there certain products that are getting refunded more than others?
--Use Case when to get the refund rate, clean product_name data, and to calculate amount of orders
--Group by 1 to see breakdown by product_name
SELECT case when product_name = '27in"" 4k gaming monitor' then '27in 4k gaming monitor' else orders.product_name end as product_name_cleaned,
  sum(CASE WHEN order_status.refund_ts is null then 0 else 1 end) as refunds,
  round(avg(CASE WHEN order_status.refund_ts is null then 0 else 1 end),2) as refund_rate
FROM core.orders
LEFT JOIN core.order_status
ON orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC;

--What is the most popular product by region?
--The first CTE selects the product_name then counts the total orders of that product name and then the region those orders were made
--The second CTE uses row_number to rank the total_orders by region per product
--The last select statement selects the region, order_count, and top order ranking in the ranked orders table
with sales_by_product as (SELECT geo_lookup.region as region,
  orders.product_name,
  COUNT (distinct orders.id) as total_orders
FROM core.orders
LEFT JOIN core.customers
ON orders.customer_id = customers.id
LEFT JOIN core.geo_lookup
ON geo_lookup.country = customers.country_code
GROUP BY 1, 2),

ranked_orders as (
SELECT *,
  row_number() over (partition by region order by total_orders desc) as order_ranking
FROM sales_by_product
ORDER BY 4 asc)

SELECT *
FROM ranked_orders
WHERE order_ranking = 1;

-- Which marketing channel has the highest average signup rate for the loyalty program compared to the marketing channel that has the highest number of loyalty program participants?
-- Calculate the signup rate using the average
-- Calculate the total loyalty participants using sum function

SELECT marketing_channel,
  round(avg(loyalty_program) as loyalty_signup_rate,
  sum(loyalty_program) as loyalty_signup_count
FROM core.customers
GROUP BY 1
ORDER BY 2 DESC;
