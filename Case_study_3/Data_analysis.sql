--B. Data Analysis Questions
--1 How many customers has Foodie-Fi ever had?
--2 What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
--3 What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
--4 What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
--5 How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
--6 What is the number and percentage of customer plans after their initial free trial?
--7 What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
--8 How many customers have upgraded to an annual plan in 2020?
--9 How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
--10 Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
--11 How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

--1
select count(distinct customer_id) from foodie_fi.subscriptions;


--2
with newd as(
select *, TO_CHAR(start_date, 'Month') as mnth

from foodie_fi.subscriptions
where plan_id='0')
select mnth, count(plan_id) as trial_distb
from newd 
group by mnth;

--3
with newd as(
select subscriptions.plan_id,start_date, plan_name, EXTRACT(year FROM start_date) as yer
from foodie_fi.subscriptions
  join foodie_fi.plans
  on 
  plans.plan_id=subscriptions.plan_id
)
-- select * from newd


select plan_name,count(plan_name)
from newd
where yer>2020
group by plan_name
;
--4
with cte as(
	SELECT 
		COUNT(DISTINCT(s.customer_id)) as total_customer_count,
		COUNT(CASE
				WHEN p.plan_name='churn' THEN 1
			  END) as churned_customer_count
	FROM foodie_fi.subscriptions s
	JOIN foodie_fi.plans p
		ON s.plan_id = p.plan_id)
	SELECT
		*,
		ROUND((churned_customer_count::numeric/total_customer_count::numeric)*100,1) as churn_customers_percentage
	FROM cte;
                   
--5
with cte as(
	SELECT 
		s.customer_id,
		s.start_date,
		p.plan_name,
		LEAD(p.plan_name,1) OVER(partition by s.customer_id order by s.start_date) as next_plan
	FROM foodie_fi.subscriptions s
	JOIN foodie_fi.plans p
		ON s.plan_id = p.plan_id)
		SELECT 
			COUNT(*) no_of_customers_churned,
			ROUND((COUNT(*)::numeric/1000::numeric)*100) as churned_customers_percentage
		FROM cte
		WHERE plan_name='trial' and next_plan='churn';
        
--6
with newd as(select customer_id, plan_name,
Rank() OVER(partition by customer_id ORDER BY start_date) as pos
             from foodie_fi.subscriptions
             join foodie_fi.plans on 
             plans.plan_id=subscriptions.plan_id
             )
             select count(*) from newd
             where pos!=1;
             
--7

select  plan_name, count(customer_id) as cust_count, round((count(customer_id)::numeric/1000::numeric)*100,2) as cust_count_prctage
from foodie_fi.subscriptions
  join foodie_fi.plans
  on 
  plans.plan_id=subscriptions.plan_id
  where start_date<='2020-12-31'
group by plan_name;

--8
with cte as(
	SELECT 
		s.customer_id,
		s.start_date,
		p.plan_name
  
  
	FROM foodie_fi.subscriptions s
	JOIN foodie_fi.plans p
		ON s.plan_id = p.plan_id
     where EXTRACT(year FROM s.start_date)=2020),
     newt as(
		SELECT LEAD(plan_name,1) OVER(partition by customer_id order by start_date) as next_plan
     from cte)
			select COUNT(*) no_of_customers_upgraded
			
		FROM newt
		WHERE next_plan='pro annual';
        
--9
with newd as(
select customer_id, plan_name, start_date
  from foodie_fi.subscriptions
  join foodie_fi.plans
  on plans.plan_id=subscriptions.plan_id
  where plan_name='trial' or plan_name='pro annual'
),
newt as(
SELECT 
		customer_id,
		start_date,
		plan_name,
		LEAD(start_date,1) OVER(partition by customer_id order by start_date) as next_date
	FROM newd)
    select avg( next_date-start_date)
    from newt 
    where next_date is not null;
    
 --10
 with newd as(
select customer_id, plan_name, start_date
  from foodie_fi.subscriptions
  join foodie_fi.plans
  on plans.plan_id=subscriptions.plan_id
  where plan_name='trial' or plan_name='pro annual'
),
newt as(
SELECT 
		customer_id,
		start_date,
		plan_name,
		LEAD(start_date,1) OVER(partition by customer_id order by start_date) as next_date
	FROM newd),
    newt2 as(
      select
     next_date-start_date as days
    from newt
    where next_date is not null),
    newt3 as(
      select *,
      CASE
			WHEN days <=30 THEN '0-30 days'
			WHEN days <=60 THEN '31-60 days'
			WHEN days <=90 THEN '61-90 days'
			WHEN days <=120 THEN '91-120 days'
			WHEN days <=120 THEN '91-120 days'
			WHEN days <=150 THEN '121-150 days'
			WHEN days <=180 THEN '151-180 days'
			WHEN days <=210 THEN '181-210 days'
			WHEN days <=240 THEN '211-240 days'
			WHEN days <=270 THEN '241-270 days'
			WHEN days <=300 THEN '271-300 days'
			WHEN days <=330 THEN '301-330 days'
			WHEN days <=360 THEN '331-360 days'
		END as thirty_day_periods
      from newt2
    
    )
    select thirty_day_periods, round(avg(days),0) as avg_days
    from newt3
    group by thirty_day_periods
    order by avg_days;
    
 --11
 with cte as(
	SELECT 
		s.customer_id,
		s.start_date,
		p.plan_name
  
  
	FROM foodie_fi.subscriptions s
	JOIN foodie_fi.plans p
		ON s.plan_id = p.plan_id
     where EXTRACT(year FROM s.start_date)=2020),
     newt as(
		SELECT *, Lag(plan_name,1) OVER(partition by customer_id order by start_date) as previous_plan
     from cte)
			select COUNT(*) no_of_customers_downgraded
			
		FROM newt
		WHERE previous_plan='pro monthly' and plan_name='basic monthly';
