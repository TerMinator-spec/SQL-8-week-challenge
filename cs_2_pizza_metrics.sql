--                             PIZZA METRICS


--1. How many pizzas were ordered?
--2. How many unique customer orders were made?
--3. How many successful orders were delivered by each runner?
--4. How many of each type of pizza was delivered?
--5. How many Vegetarian and Meatlovers were ordered by each customer?
--6. What was the maximum number of pizzas delivered in a single order?
--7. How many pizzas were delivered that had both exclusions and extras?
--8. What was the total volume of pizzas ordered for each hour of the day?
--9. What was the volume of orders for each day of the week?
--10. For each customer, how many delivered pizzas had at least 1 change and how -----   many had no changes?

--Q1
select count(order_id) 
from customer_orders;

--Q2
select count(distinct customer_id)
from customer_orders;

--Q3
with newd as(
 SELECT runner_id, pickup_time, distance, duration, coalesce(cancellation, 'data_unavailable') AS iscanceled
  from runner_orders
  )
  select count(*)
  from newd
  where iscanceled not like '%Cancel%';
  
--Q4
with filv as(
 SELECT order_id, coalesce(cancellation, 'data_unavailable') as cancellation
  from runner_orders
  ),
newd as(
 select customer_orders.order_id,pizza_id, cancellation
  from customer_orders
  left join filv
  on customer_orders.order_id=filv.order_id
  where cancellation not like '%Cancel%'

)
select count(*), pizza_name
from newd
join pizza_names
on newd.pizza_id=pizza_names.pizza_id
group by pizza_name
;

--Q5
select customer_id, pizza_name, count(*)
from customer_orders
join pizza_names
on customer_orders.pizza_id=pizza_names.pizza_id
group by customer_id, pizza_name
order by customer_id;

--Q6
with newd as(select order_id, count(*)
from customer_orders
group by order_id)

select max(count)
from newd;


--Q7
with filv as(
 SELECT order_id, coalesce(cancellation, 'data_unavailable') as cancellation
  from runner_orders
  ),
newd as(
 select customer_orders.order_id,
CASE WHEN extras IS NULL THEN 'null'
WHEN extras='' THEN 'null'
ELSE extras
END as extras, CASE WHEN exclusions IS NULL THEN 'null'
WHEN exclusions='' THEN 'null'
ELSE exclusions
END as exclusions
  from customer_orders
  left join filv
  on customer_orders.order_id=filv.order_id
  where cancellation not like '%Cancel%'

)
select count(*) 
from newd
where exclusions!='null' and extras!='null';

--Q8
select count(*), 
CAST( EXTRACT (hour from order_time) AS INT) AS hour_of_day
from customer_orders
group by hour_of_day;

--Q9
SELECT
	to_char(order_time, 'Day') AS weekday, 
	COUNT(distinct order_id) AS number_of_orders
FROM customer_orders
GROUP BY 
	weekday;
    
 --Q10
 with filv as(
 SELECT order_id, coalesce(cancellation, 'data_unavailable') as cancellation
  from runner_orders
  ),
newd as(
 select customer_orders.order_id, customer_id,
CASE WHEN extras IS NULL THEN 'null'
WHEN extras='' THEN 'null'
ELSE extras
END as extras, CASE WHEN exclusions IS NULL THEN 'null'
WHEN exclusions='' THEN 'null'
ELSE exclusions
END as exclusions
  from customer_orders
  left join filv
  on customer_orders.order_id=filv.order_id
  where cancellation not like '%Cancel%'

)
select customer_id,
sum(case when extras='null' and exclusions='null' then 1 else 0 end) as no_change,
sum(case when extras!='null' or exclusions!='null' then 1 else 0 end) as atleast_1_change
from newd
group by customer_id
order by customer_id;
