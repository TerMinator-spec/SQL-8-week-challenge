--                A. Customer Nodes Exploration
--1 How many unique nodes are there on the Data Bank system?
--2 What is the number of nodes per region?
--3 How many customers are allocated to each region?
--4 How many days on average are customers reallocated to a different node?
--5 What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

--1
select count(distinct node_id) from data_bank.customer_nodes;

--2
select region_name,count(distinct node_id) as num_nodes
from data_bank.customer_nodes
join data_bank.regions 
on regions.region_id=customer_nodes.region_id
group by region_name;

--3
select region_name, count(customer_id) as number_of_customers
from data_bank.customer_nodes
join data_bank.regions 
on regions.region_id=customer_nodes.region_id
group by region_name;

--4
select customer_id, node_id, avg(end_date-start_date) as avg_num_days from data_bank.customer_nodes
group by customer_id, node_id
order by customer_id
