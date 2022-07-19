--refrence: https://8weeksqlchallenge.com/case-study-2/
--All questions and database are availble in above link
--linkedin hastag: #8WeekSQLChallenge




--Data cleaning

--Make refine table for ruuners_order

drop table if exists runner_orders_refined
create table runner_orders_refined (
									order_id int,
									runner_id int,
									pickup_time datetime,
									distance_km float,
									duration_min int,
									cancellation varchar(50)
									)

insert into runner_orders_refined
							select 
								order_id,
								runner_id,
								cast(iif(pickup_time like '%[0-9]%',pickup_time,null) as datetime) as pickup_time,
								cast(iif(ISNUMERIC(REPLACE(distance,'km',''))=1,REPLACE(distance,'km',''),null) as float) as distance_km,
								cast(iif(dbo.udf_GetNumeric(duration) <>'', dbo.udf_GetNumeric(duration), null) as int) as duration_min,
								iif(cancellation in ('Restaurant Cancellation','Customer Cancellation'),cancellation,null) as cancellation	
							from runner_orders

select * from runner_orders_refined


--Make refine table for customer_orders


drop table if exists customer_orders_refined
create table customer_orders_refined (
									order_id int,
									customer_id int,
									pizza_id int,
									exclusions varchar(4),
									extras varchar(4),
									order_time datetime
									)
insert into customer_orders_refined
							select
								order_id,
								customer_id,
								pizza_id,
								case
									when exclusions = 'null' then null
									when exclusions = '' then null
									else exclusions
								end as exclusions,
								case
									when extras = 'null' then null
									when extras = '' then null
									else extras
								end as extras,
								order_time
							from customer_orders

select * from customer_orders_refined



--A.1
--Count pizza_id column 

select
	count(pizza_id) as order_count
from customer_orders_refined

--A.2
--Count distinct values for customer_id

select
	count(distinct customer_id) as unique_customer_order
from customer_orders_refined

--A.3
--Filter on not cancelled, then count orders per runner

select
	runner_id,
	COUNT(order_id) as delivered_order
from runner_orders_refined
where cancellation is null
group by runner_id
order by delivered_order desc

--A.4
--Make temp table by joining customer and runner
--Left join above table to pizza_names and convert text values to varchar 


drop table if exists #customer_runner
create table #customer_runner (
								order_id int,
								runner_id int,
								pickup_time datetime,
								distance_km float,
								duration_min int,
								cancellation varchar(50),
								customer_id int,
								pizza_id int,
								exclusions varchar(4),
								extras varchar(4),
								order_time datetime
								)

insert into #customer_runner
						select 
							ro.order_id,
							ro.runner_id,
							ro.pickup_time,
							ro.distance_km,
							ro.duration_min,
							ro.cancellation,
							co.customer_id,
							co.pizza_id,
							co.exclusions,
							co.extras,
							co.order_time
						from runner_orders_refined as ro
						left join customer_orders_refined co
						on ro.order_id = co.order_id



select
	convert(varchar,pn.pizza_name) as pizza_name,
	count(convert(varchar,pn.pizza_name)) as delivered_pizza
from #customer_runner as cr
left join pizza_names as pn
on cr.pizza_id = pn.pizza_id
where cr.cancellation is null
group by convert(varchar,pn.pizza_name);

--A.5
--Remove filter from cancellation and add customer_id to above query

select
	cr.customer_id,
	convert(varchar,pn.pizza_name) as pizza_name,
	count(convert(varchar,pn.pizza_name)) as ordered_pizza
from #customer_runner as cr
left join pizza_names as pn
on cr.pizza_id = pn.pizza_id
group by convert(varchar,pn.pizza_name), cr.customer_id;

--A.6
--Find maximum number of delivered pizza using CTE

with cte_max_pizza_delivered  as(

								select
									order_id,
									count(pizza_id) as delivered_pizza
								from #customer_runner
								where cancellation is null 
								group by order_id
								)
select 
	max(delivered_pizza) as max_delivered_pizza
from cte_max_pizza_delivered;

--A.7
--Use exclusions and extras to build pizza_change column
--Then group them by customer and chnage status using CTE

with cte_changed_pizza as(
						select
							customer_id,
							case
								when exclusions is null and extras is null then 'No changes'
								else 'Changed'
							end as pizza_change
						from #customer_runner
						where cancellation is null
						)
select 
	customer_id,
	pizza_change,
	COUNT(pizza_change) as total_count
from cte_changed_pizza
group by customer_id, pizza_change
order by customer_id;

--A.8
--Use above query and change conditions for when statement
--Then filter it on 'Yes' using CTE

with cte_exclusion_and_extras as(
						select
							case
								when exclusions is not null and extras is not null then 'Yes'
								else 'No'
							end as exclu_extra
						from #customer_runner
						where cancellation is null
						)
select
	count(exclu_extra) as exclu_extra_count
from cte_exclusion_and_extras
where exclu_extra = 'Yes';

--A.9
--Extract hour from order time and count ordered pizza for that

select	
	DATEPART(HOUR,order_time) as day_hour,
	COUNT(pizza_id) as total_count
from customer_orders_refined
group by DATEPART(HOUR,order_time) 

--A.10
--Use above query and replace datepart with datename function

select	
	datename(WEEKDAY,order_time) as day_day,
	COUNT(pizza_id) as total_count
from customer_orders_refined
group by datename(WEEKDAY,order_time) 

--B.1
--As 2021-01-01 was friday we set fisrt day of year 5
--Group by registration count per week number

set datefirst 5;

select 
	DATEPART(WEEK,registration_date) as week_num,
	COUNT(runner_id) as register_count
from runners
group by DATEPART(WEEK,registration_date);

--B.2
--Find pickup duration per each order
--Then group it by runner_id using CTE


with cte_pickup_duration as (
								select
									order_id,
									runner_id,
									avg(DATEDIFF(MINUTE,order_time,pickup_time)) as pickup_duration
								from #customer_runner
								group by order_id, runner_id
							)
select
	runner_id,
	AVG(pickup_duration) as avg_pickup_min
from cte_pickup_duration
group by runner_id;

--B.3
--Find pizza count in each order and add pickup duration which is also preparation time
--Compare time and pizza counts

select
	order_id,
	count(pizza_id) as pizza_count_in_order,
	avg(DATEDIFF(MINUTE,order_time,pickup_time)) as pickup_duration_min
	from #customer_runner
group by order_id
order by avg(DATEDIFF(MINUTE,order_time,pickup_time)) 



--B.4
--Group by average distance for each customer

select 
	customer_id,
	avg(distance_km) as avg_distance_km
from #customer_runner
group by customer_id

--B.5

select
	Max(duration_min)-MIN(duration_min) as max_min_diff
from runner_orders_refined

--B.6
--Devide distance on time to find out apeed

select
	runner_id,
	order_id,
	distance_km/duration_min/60 as speed_km_per_hour
from runner_orders_refined
order by distance_km/duration_min/60 desc;

--B.7
--Count delivered and not delivered orders by two temp tables
--Join Tables to calculate delivery rate per each runner

drop table if exists #delivered
create table #delivered (
						runner_id int,
						delivered float
						)

insert into #delivered
				select
				runner_id,
				count(*) as delivered						
				from runner_orders_refined
				where cancellation is null
				group by runner_id




drop table if exists #total_order
create table #total_order (
						runner_id int,
						total_order float
						)

insert into #total_order
				select
				runner_id,
				count(*) as total_order						
				from runner_orders_refined
				group by runner_id

select
	t.runner_id,
	delivered/total_order*100 as delivery_percentage
from #total_order as t
left join #delivered as d
on t.runner_id = d.runner_id;


--C.1
--Split toppings for each pizza type
--Then join them with toppings and pizza name tables using CTE

with cte_pizza_split as (
					select
						pizza_id,
						trim(value) as topping_code
					from
					pizza_recipes
					cross apply string_split(cast(pizza_recipes.toppings as varchar),',')
					)
select 
	pizza_name,
	topping_name
from cte_pizza_split as s
left join pizza_toppings as t
on s.topping_code= t.topping_id
left join pizza_names as n
on s.pizza_id = n.pizza_id;

--C.2
--Extract extras and join them with topping names using CTE
--Count extras and sort them from max to min

with cte_order_split as (
							select
								t.topping_name
							from
							customer_orders_refined
							cross apply string_split(cast(customer_orders_refined.extras as varchar),',')
							left join pizza_toppings as t
							on t.topping_id = trim(value) 
						)
select
	cast(topping_name as varchar) as topping_name,
	COUNT(cast(topping_name as varchar)) as extras_count
from cte_order_split
group by cast(topping_name as varchar)
order by 2 desc;


--C.3
--Do the same thing as above query for exclusion

with cte_order_split_exclusion as (
							select
								t.topping_name
							from
							customer_orders_refined
							cross apply string_split(cast(customer_orders_refined.exclusions as varchar),',')
							left join pizza_toppings as t
							on t.topping_id = trim(value) 
						)
select
	cast(topping_name as varchar) as topping_name,
	COUNT(cast(topping_name as varchar)) as extras_count
from cte_order_split_exclusion
group by cast(topping_name as varchar)
order by 2 desc;

--C.4
--Set needed conditions in when statement then join table with pizza_names


select
	o.order_id,
	o.customer_id,
	o.pizza_id,
	o.exclusions,
	o.extras,
	o.order_time,
	case
		when o.pizza_id='1'and CHARINDEX('4',exclusions)+CHARINDEX('1',exclusions)>1 and CHARINDEX('6',extras)+CHARINDEX('9',extras)>1 then 'Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers'
		when o.pizza_id='1'and CHARINDEX('1',extras)>0 then 'Meat Lovers - Extra Bacon'
		when o.pizza_id='1'and CHARINDEX('3',exclusions)>0 then 'Meat Lovers - Exclude Beef'
		else n.pizza_name
	end as order_item
from customer_orders_refined as o
left join pizza_names as n
on n.pizza_id = o.pizza_id;

--D.1
--Make price column using CTE and sum it all

with cte_price as (
					select
						*,
						iif(pizza_id=1,12,10) as price
					from #customer_runner
					)
select 
	sum(price) as total_sales
from cte_price
where cancellation is null;


--D.2
--Set condition for extras prices in CTE, then sum up all sales


with cte_price_extras as (
					select
						*,
						iif(pizza_id=1,12,10) as price,
						case
							when extras is null then 0
							when len(extras)>1 and CHARINDEX('4',extras) =0 then 2
							when len(extras)>1 and CHARINDEX('4',extras) <>0 then 3
							when extras in ('1','2','3','5','6','7','8','9','10','11','12') then 1
							when extras = '4' then 2
							else null
						end as extras_price,
						iif(pizza_id=1,12,10) + case
							when extras is null then 0
							when len(extras)>1 and CHARINDEX('4',extras) =0 then 2
							when len(extras)>1 and CHARINDEX('4',extras) <>0 then 3
							when extras in ('1','2','3','5','6','7','8','9','10','11','12') then 1
							when extras = '4' then 2
							else null
						end as total_price
					from #customer_runner
					)
select 
	sum(total_price) as total_sales
from cte_price_extras
where cancellation is null;

--D.3
--Make new table with two columns of order id and score

drop table if exists order_score
create table order_score (
							order_id int,
							score int
							)
insert into order_score
values
		(1,2),
		(2,4),
		(3,3),
		(4,1),
		(5,3),
		(7,4),
		(8,5),
		(10,3)
						
--D.4
--Join new table with order_score

select
	customer_id,
	c.order_id,
	runner_id,
	score,
	order_time,
	pickup_time,
	DATEDIFF(MINUTE,order_time,pickup_time) as order_pickup_diff_minute,
	duration_min,
	count(c.order_id) over (partition by c.order_id) as total_number_pizza,
	distance_km/duration_min*60 as speed_km_per_hour
from #customer_runner as c
left join order_score as s
on c.order_id = s.order_id
where cancellation is null;

--D.5
--Make travel expense column per each order 
--Subtract travel expense from price to reach left_over
--Sum left_over using CTE

with cte_price_distance as (
					select
						*,
						iif(pizza_id=1,12,10) as price,
						distance_km*0.3*iif(ROW_NUMBER() over (partition by order_id order by order_id)=1,1,0) as travel_expense,
						iif(pizza_id=1,12,10)-distance_km*0.3*iif(ROW_NUMBER() over (partition by order_id order by order_id)=1,1,0) as left_over						
					from #customer_runner
					)
select 
	sum(left_over) as net_income
from cte_price_distance
where cancellation is null;

--E
--Two tables of pizza_names and pizza_recipes should be updated

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  "pizza_id" INTEGER,
  "pizza_name" TEXT
);
INSERT INTO pizza_names
  ("pizza_id", "pizza_name")
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian'),
  (3, 'Supreme');

DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  "pizza_id" INTEGER,
  "toppings" TEXT
);
INSERT INTO pizza_recipes
  ("pizza_id", "toppings")
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12'),
  (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');
