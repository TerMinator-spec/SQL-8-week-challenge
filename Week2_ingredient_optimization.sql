-- Ingredient Optimization
-- 1 What are the standard ingredients for each pizza?
-- 2 What was the most commonly added extra?
-- 3 What was the most common exclusion?
-- 4 Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
-- 5 Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
-- 6 What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

--Q2
WITH split_orders AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
		exclusions,
		extras,
		CAST(UNNEST(string_to_array(COALESCE(extras, '0'), ',')) AS INT) AS extras_col,
		order_time
	FROM
		pizza_runner.customer_orders
        where extras!='null'
), newd as(
             select extras_col, count(*) as cnt
             from split_orders
             group by extras_col
             order by cnt desc
)
             
             select topping_name, cnt
             from newd
             join pizza_runner.pizza_toppings
             on pizza_toppings.topping_id=newd.extras_col
             limit 1;
             
--Q3
             WITH split_orders AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
		exclusions,
		extras,
		CAST(UNNEST(string_to_array(COALESCE(exclusions, '0'), ',')) AS INT) AS ex_col,
		order_time
	FROM
		pizza_runner.customer_orders
        where exclusions!='null'
), newd as(
             select ex_col, count(*) as cnt
             from split_orders
             group by ex_col
             
)
             
             select topping_name, cnt
             from newd
             join pizza_runner.pizza_toppings
             on pizza_toppings.topping_id=newd.ex_col
             order by cnt desc
             limit 1;
             ;
             
--Q4   -- preparing a good table
             
             with gtable as(
             select order_id,
               pizza_name,
             customer_id,
             customer_orders.pizza_id,
             case when exclusions='null' then '0'
             when exclusions is NULL then '0'
             when exclusions='' then '0'
             else exclusions end,
             case when extras='null' then '0'
             when extras is NULL then '0'
             when extras='' then '0'
             else extras end
             from pizza_runner.customer_orders
             join pizza_runner.pizza_names
             on pizza_names.pizza_id=customer_orders.pizza_id
             order by order_id),
             split_orders AS (
	SELECT
		order_id,
		customer_id,
		pizza_id,
        pizza_name,
		exclusions,
		extras,
		CAST(UNNEST(string_to_array(extras, ',')) AS INT) AS extras_col
        
		
	FROM
		gtable
         
        
), split_ord as(
     select *, 
  CAST(UNNEST(string_to_array(exclusions, ',')) AS INT) AS exclusion_col
              from split_orders
              
),
       --select * from split_ord
    fin_ord as(         SELECT order_id, pt1.topping_name as incl, pizza_name,
       pt2.topping_name as excl FROM split_ord
left JOIN pizza_runner.pizza_toppings as pt1  ON pt1.topping_id = split_ord.extras_col

left JOIN pizza_runner.pizza_toppings as pt2  ON pt2.topping_id = split_ord.exclusion_col), 
       ekorord as (
       select order_id,
       case when incl is null and excl is null then pizza_name
            when incl is null and excl is not null then concat(pizza_name,' exclude ',excl)
            when incl is not null and excl is null then concat(pizza_name,' include ',incl)
            when incl!='null' and excl!='null' then concat(pizza_name,' include ',incl,' exclude ',excl) else pizza_name end as req
       from fin_ord)
       
       
       select *
       --case when req like '%include Bacon' then 'Meat Lovers - Extra Bacon'
       --when req like '%exclude Bacon%' or req like '%exclude Cheese%' then 'Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers'
       --else req end as tum
       from ekorord
