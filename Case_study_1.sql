/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Question 1 done
SELECT sum(price), customer_id  	
FROM sales
join menu
on sales.product_id = menu.product_id
group by customer_id;

-- Question 2
select count(distinct order_date), customer_id
from sales
group by customer_id;

-- Question 3
with newd as (SELECT Rank() OVER(partition by customer_id ORDER BY order_date), customer_id, product_name
FROM sales
join menu
on sales.product_id=menu.product_id
order by customer_id)
select customer_id, product_name
from newd
where rank=1;

-- Question 4
with req_tab as (
SELECT * 	
FROM sales
join menu
on sales.product_id = menu.product_id

)
select count(*), product_name
from req_tab
group by product_name
limit 1;

-- Question 5
with newd as (SELECT customer_id, product_name, count(*) as no_of_products

FROM sales
join menu
on sales.product_id = menu.product_id
group by customer_id, product_name
order by customer_id),

newt as (
select Rank() OVER(partition by customer_id ORDER BY no_of_products desc) as st, *
from newd
)
select *
from newt
where st=1;

-- Question 6
with newd as (select sales.customer_id,product_id, order_date, join_date
              from sales
              left join members
              on sales.customer_id=members.customer_id
             ),
             
newt as (
select Rank() OVER(partition by customer_id ORDER BY order_date) as st, *
from newd
where order_date>=join_date)
select *
from newt
join menu
on newt.product_id=menu.product_id
where st=1;

-- Question 7
with newd as (select sales.customer_id,product_id, order_date, join_date
              from sales
              join members
              on sales.customer_id=members.customer_id
             ),
             
newt as (
select Rank() OVER(partition by customer_id ORDER BY order_date desc) as st, *
from newd
where order_date<join_date)
select *
from newt
join menu
on newt.product_id=menu.product_id
where st=1;

-- Question 8
with newd as (select sales.customer_id,product_id, order_date, join_date
              from sales
              join members
              on sales.customer_id=members.customer_id
             ),
             
newt as (
select Rank() OVER(partition by customer_id ORDER BY order_date desc) as st, *
from newd
where order_date<join_date)
select sum(price) as money_spent, count(*) as items, customer_id
from newt
join menu
on newt.product_id=menu.product_id
group by customer_id;

--Question 9

with newd as (select customer_id, product_name, sum(price) as tot_price
from sales
join menu
on sales.product_id=menu.product_id
group by customer_id, product_name)

select customer_id, sum(case when (product_name='sushi') then tot_price*2*10 else tot_price*10 end) from newd
group by customer_id
order by customer_id;

--Question 10

with newd as (select join_date, join_date + 7 as first_week, sales.customer_id,sales.product_id, order_date
              from sales
              join members
              on sales.customer_id=members.customer_id
              -- join menu on sales.product_id=menu.product_id
              where (order_date>='2021-01-01') 
              and (order_date<='2021-01-31')
             ),
             newt as(
             select menu.price as tot,* 
             from newd
             join menu
             on newd.product_id=menu.product_id
               )
               -- select * from newt
              select customer_id, sum(case when (order_date>=join_date and        order_date<=first_week) 
                         then tot*2*10 else case when (newt.product_name='sushi') then tot*2*10 else tot*10 end end ) as points
                from newt
                group by customer_id
                order by customer_id;
             
