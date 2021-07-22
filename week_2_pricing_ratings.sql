--Pricing and Ratings
-- 1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
-- 2 What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
-- 3 The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
-- 4 Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas
-- 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

-- clean the table
DROP TABLE IF EXISTS customer_orders_cleaned;
CREATE TEMP TABLE customer_orders_cleaned AS WITH first_layer AS (
  SELECT
    order_id,
    customer_id,
    pizza_id,
    CASE
      WHEN exclusions = '' THEN NULL
      WHEN exclusions = 'null' THEN NULL
      ELSE exclusions
    END as exclusions,
    CASE
      WHEN extras = '' THEN NULL
      WHEN extras = 'null' THEN NULL
      ELSE extras
    END as extras,
    order_time
  FROM
    pizza_runner.customer_orders
)
SELECT
  ROW_NUMBER() OVER (
    ORDER BY
      order_id
      -- pizza_id
  ) AS row_number_order,
  order_id,
  customer_id,
  pizza_id,
  exclusions,
  extras,
  order_time
FROM
  first_layer;
  
  ----------
  DROP TABLE IF EXISTS runner_orders_cleaned;
CREATE TEMP TABLE runner_orders_cleaned AS WITH first_layer AS (
  SELECT
    order_id,
    runner_id,
    CAST(
      CASE
        WHEN pickup_time = 'null' THEN NULL
        ELSE pickup_time
      END AS timestamp
    ) AS pickup_time,
    CASE
      WHEN distance = '' THEN NULL
      WHEN distance = 'null' THEN NULL
      ELSE distance
    END as distance,
    CASE
      WHEN duration = '' THEN NULL
      WHEN duration = 'null' THEN NULL
      ELSE duration
    END as duration,
    CASE
      WHEN cancellation = '' THEN NULL
      WHEN cancellation = 'null' THEN NULL
      ELSE cancellation
    END as cancellation
  FROM
    pizza_runner.runner_orders
)
SELECT
  order_id,
  runner_id,
  pickup_time,
  CAST(
    regexp_replace(distance, '[a-z]+', '') AS DECIMAL(5, 2)
  ) AS distance,
  CAST(regexp_replace(duration, '[a-z]+', '') AS INT) AS duration,
  cancellation
FROM
  first_layer;
  select * from runner_orders_cleaned;
--1
with newt as(
select customer_orders.pizza_id, pizza_name, coalesce(cancellation, 'null') as cancellation,
case when pizza_name='Meatlovers' then 12
else 10 end as moneyf
from pizza_runner.customer_orders
join pizza_runner.pizza_names
on pizza_names.pizza_id=customer_orders.pizza_id
join pizza_runner.runner_orders
on runner_orders.order_id=customer_orders.order_id
)

select sum(moneyf)
from newt
where cancellation not like '%Cancel%';

--2
with gtable as(
             select order_id,
              
             customer_orders.pizza_id,
             case when exclusions='null' then '0'
             when exclusions is NULL then '0'
             when exclusions='' then '0'
             else exclusions end as excl,
             case when extras='null' then '0'
             when extras is NULL then '0'
             when extras='' then '0'
             else extras end as ext
             from pizza_runner.customer_orders
             ),
newt as(
select gtable.order_id, gtable.pizza_id, pizza_name, coalesce(cancellation, 'null') as cancellation,
  case when ext!='0' then length(ext)/3 +1
  else 0 end as num_d,
case when pizza_name='Meatlovers' then 12
else 10 end as moneyf
from gtable
join pizza_runner.pizza_names
on pizza_names.pizza_id=gtable.pizza_id
join pizza_runner.runner_orders
on runner_orders.order_id=gtable.order_id

)

                                                                                        select sum(moneyf+num_d) from newt
                                                                                        where cancellation not like '%Cancel%';
                                                                                   
-- Q3

DROP TABLE IF EXISTS rating_system;
CREATE TABLE rating_system (
  "order_id" INTEGER,
  "rating" INTEGER CONSTRAINT check1to5_rating CHECK (
    "rating" between 1
    and 5
  ),
  "review" VARCHAR(150)
);
INSERT INTO rating_system
  ("order_id", "rating", "review")
 Values
 ('1', '2', 'Good'),
  ('2', '4', 'Great Pizza'),
  ('3', '4', 'East or west, Pizza runner is the best'),
  ('4', '1', 'Really bad taste'),
  ('5', '2', ''),
  ('6', NULL, ''),
  ('7', '5', ''),
  ('8', '4', 'Delicious'),
  ('9', NULL, ''),
  ('10', '1', 'Disappointed');
  -- Q4
  with newt as(
    select order_id, max(customer_id) as customer_id, max(order_time) as order_time, count(customer_id) as num_pizza
    from customer_orders_cleaned
    group by order_id
    order by order_id
  )
  
  select rating_system.order_id,
  rating,
  review,
  runner_id,
  pickup_time,
  distance,
  duration,
  customer_id,
  order_time,
  num_pizza,
  pickup_time-order_time as cook_time,
  distance/duration as avg_speed
  from rating_system
  join runner_orders_cleaned 
  on rating_system.order_id=runner_orders_cleaned.order_id
  join newt
  on rating_system.order_id=newt.order_id
  
  where cancellation is Null;
  
 -- Q5
 with newt as(
select customer_orders_cleaned.order_id,customer_orders_cleaned.pizza_id, pizza_name, distance,
case when pizza_name='Meatlovers' then 12
else 10 end as moneyf
from customer_orders_cleaned
join pizza_runner.pizza_names
on pizza_names.pizza_id=customer_orders_cleaned.pizza_id
join runner_orders_cleaned
on runner_orders_cleaned.order_id=customer_orders_cleaned.order_id
   
)
select sum(moneyf-distance*0.30) from newt
where distance is not null;
