--Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

with newd as(
  select * from foodie_fi.subscriptions
  where customer_id<=2 or (customer_id>=11 and customer_id<=19)
)
select * from newd
join foodie_fi.plans on 
plans.plan_id=newd.plan_id
order by customer_id, start_date
