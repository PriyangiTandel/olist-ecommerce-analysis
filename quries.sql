-- Olist e-commerce analysis: key SQL queries (SQLite)
-- Rule used throughout: revenue counts only delivered orders.

-- 1. Orders by status
select order_status, count(*) as total_orders
from olist_orders
group by order_status
order by total_orders desc;

-- 2. Revenue by month
select strftime('%Y-%m', o.order_purchase_timestamp) as month,
       count(distinct o.order_id) as orders,
       round(sum(i.price), 2) as revenue
from olist_orders o
join olist_order_items i on o.order_id = i.order_id
where o.order_status = 'delivered'
group by month
order by month;

-- 3. Top 10 categories by revenue
select t.product_category_name_english as category,
       count(distinct o.order_id) as orders,
       round(sum(i.price), 2) as revenue
from olist_order_items i
join olist_orders o on i.order_id = o.order_id
join olist_products p on i.product_id = p.product_id
join product_category t on p.product_category_name = t.product_category_name
where o.order_status = 'delivered'
group by category
order by revenue desc
limit 10;

-- 4. Orders and revenue by state
select c.customer_state as state,
       count(distinct o.order_id) as orders,
       round(sum(i.price), 2) as revenue
from olist_orders o
join olist_order_items i on o.order_id = i.order_id
join olist_customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by state
order by revenue desc;

-- 5. Average delivery time (days) by state
select c.customer_state as state,
       count(*) as orders,
       round(avg(julianday(o.order_delivered_customer_date)
               - julianday(o.order_purchase_timestamp)), 1) as avg_days
from olist_orders o
join olist_customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
  and o.order_delivered_customer_date <> ''
group by state
order by avg_days desc;

-- 6. Late vs on-time orders: review score and share of 1-star reviews
select case when o.order_delivered_customer_date > o.order_estimated_delivery_date
            then 'late' else 'on_time' end as delivery,
       count(*) as reviews,
       round(avg(r.review_score), 2) as avg_score,
       round(100.0 * sum(case when r.review_score = 1 then 1 else 0 end) / count(*), 1) as pct_one_star
from olist_orders o
join olist_order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
  and o.order_delivered_customer_date <> ''
group by delivery;

-- 7. Share of late orders by state (states with 100+ orders)
select c.customer_state as state,
       count(*) as orders,
       sum(case when o.order_delivered_customer_date > o.order_estimated_delivery_date
                then 1 else 0 end) as late_orders,
       round(100.0 * sum(case when o.order_delivered_customer_date > o.order_estimated_delivery_date
                              then 1 else 0 end) / count(*), 1) as pct_late
from olist_orders o
join olist_customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
  and o.order_delivered_customer_date is not null
  and o.order_delivered_customer_date <> ''
group by state
having count(*) >= 100
order by pct_late desc;
