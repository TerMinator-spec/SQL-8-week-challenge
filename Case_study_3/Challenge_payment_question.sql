with newd as(
select customer_id,start_date, subscriptions.plan_id, plan_name, price, LEAD(plan_name,1) OVER(partition by customer_id order by start_date) as next_plan,
  Lag(plan_name,1) OVER(partition by customer_id order by start_date) as last_plan,LEAD(start_date,1) OVER(partition by customer_id order by start_date) as next_date, Lag(price,1) OVER(partition by customer_id order by start_date) as last_price
from foodie_fi.subscriptions

join foodie_fi.plans
on subscriptions.plan_id=plans.plan_id
where extract(year from start_date)<=2020 and plan_name!='trial'
order by subscriptions.customer_id, start_date),
  
  newt as(
  select customer_id, plan_id, plan_name, price,
    
  case when plan_name='basic monthly' and next_plan is null then generate_series(
  start_date, date '2020-12-31', '1 month')
when plan_name='basic monthly' and (next_plan = 'pro monthly' or next_plan='pro annual') then generate_series(start_date, next_date, '1 month')
when plan_name='basic monthly' and next_plan = 'churn' then generate_series(
  start_date, next_date, '1 month')
  
  when plan_name='pro monthly' and (next_plan = 'pro annual' or next_plan='churn') then generate_series(start_date, next_date, '1 month')
  when plan_name='pro monthly' and next_plan is null then generate_series(
  start_date, date '2020-12-31', '1 month')
  
  when plan_name='pro annual' and next_plan is null then generate_series(
  start_date, date '2020-12-31', '1 year')
  end as payment_date
  from newd
  ),
  -- select * from newt
  newt2 as(
  select *, Lag(plan_name,1) OVER(partition by customer_id order by payment_date) as last_plan,Lag(price,1) OVER(partition by customer_id order by payment_date) as last_price
    from newt
  ),
  

   newt3 as(
select *,
 
  case 
when (plan_name = 'pro monthly' or plan_name='pro annual') and last_plan='basic monthly' then price-last_price
else price
  end as payment
  from newt2)
  
  
 
 select customer_id, plan_id, plan_name, payment, payment_date, Rank() OVER(partition by customer_id ORDER BY payment_date) as payment_order
 from newt3
