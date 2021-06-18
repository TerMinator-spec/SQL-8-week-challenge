--                  RUNNER AND CUSTOMER EXPERIENCE

--1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
--2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
--3 Is there any relationship between the number of pizzas and how long the order takes to prepare?
--4 What was the average distance travelled for each customer?
--5 What was the difference between the longest and shortest delivery times for all orders?
--6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
--7 What is the successful delivery percentage for each runner?
    
--Q1
select *, EXTRACT(week FROM registration_date)
from pizza_runner.runners;

--Q2
with filv as(
 SELECT order_id, runner_id, coalesce(cancellation, 'data_unavailable') as cancellation, pickup_time
  from pizza_runner.runner_orders
  ),
newd as(
 select distinct customer_orders.order_id, runner_id, order_time, TO_TIMESTAMP(pickup_time, 'YYYY/MM/DD/HH24:MI:ss') as pickup_time
  from pizza_runner.customer_orders
  left join filv
  on customer_orders.order_id=filv.order_id
  where cancellation not like '%Cancel%'

)
select runner_id,avg(pickup_time-order_time) 
from newd
group by runner_id;

--Q3
with filv as(
 SELECT order_id, coalesce(cancellation, 'data_unavailable') as cancellation, pickup_time
  from pizza_runner.runner_orders
  ),
newd as(
 select customer_orders.order_id, order_time, TO_TIMESTAMP(pickup_time, 'YYYY/MM/DD/HH24:MI:ss') as pickup_time
  from pizza_runner.customer_orders
  left join filv
  on customer_orders.order_id=filv.order_id
  where cancellation not like '%Cancel%'

)
select order_id, count(*) as num_pizzas, avg(pickup_time-order_time) as prep_time from newd
group by order_id
order by prep_time desc;
-- Seems like those who have ordered more pizzas took more time

--Q4
select distinct customer_id, avg(CAST( regexp_replace(distance, '[a-z]+', '' ) AS DECIMAL(5,2) )) AS distance
from pizza_runner.customer_orders
join pizza_runner.runner_orders
on customer_orders.order_id=runner_orders.order_id
where distance!='null'
group by customer_id;

--Q5                                      
select max(CAST(regexp_replace(duration, '[a-z]+', '' ) AS DECIMAL(12,2) ))-
 min(CAST(regexp_replace(duration, '[a-z]+', '' ) AS DECIMAL(12,2) ))as duration
 from pizza_runner.runner_orders
 where duration!='null';
 
--Q6
select order_id, runner_id, duration, distance, CAST( regexp_replace(distance, '[a-z]+', '' ) AS DECIMAL(5,2) )/CAST(regexp_replace(duration, '[a-z]+', '' ) AS DECIMAL(12,2) ) as avg_speed
 from pizza_runner.runner_orders
 where duration!='null' and distance!='null'
 ;
 
 --Q7
 with filv as(
 SELECT runner_id, coalesce(cancellation, 'data_unavailable') as cancellation
  from pizza_runner.runner_orders
  ),
   newd as( select runner_id, count(*) as tc
           from filv
           group by runner_id
   ),
          newt as(
  select runner_id,count(*) as sc
   from filv
   where cancellation not like '%Cancel%'
   group by runner_id
    
            )
          
    select newt.runner_id, sc*100/tc as sucsessful_delivery
          from newt
          join newd
          on newt.runner_id=newd.runner_id;
  
