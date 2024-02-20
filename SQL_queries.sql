--What are the quarterly trends for order count, sales and AOV, for Macbooks sold in North America across all years?

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

SELECT case when product_name = '27in"" 4k gaming monitor' then '27in 4k gaming monitor' else orders.product_name end as product_name_cleaned,
  sum(CASE WHEN order_status.refund_ts is null then 0 else 1 end) as refunds,
  round(avg(CASE WHEN order_status.refund_ts is null then 0 else 1 end),2) as refund_rate
FROM core.orders
LEFT JOIN core.order_status
ON orders.id = order_status.order_id
GROUP BY 1
ORDER BY 3 DESC;
