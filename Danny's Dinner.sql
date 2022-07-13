--refrence: https://8weeksqlchallenge.com/case-study-1/
--linkedin hastag: #8WeekSQLChallenge

--Q1
--Join sales and menu tables, then sum all prices per each customer_id

select 
	sales.customer_id,
	sum(menu.price) as total_sales
from sales
left join menu
on sales.product_id = menu.product_id
group by sales.customer_id
order by total_sales desc;

--Q2
--Count distinct order_date per each customer_id

select 
	sales.customer_id,
	count(distinct sales.order_date) as visited_days
from sales
group by sales.customer_id
order by visited_days desc;

--Q3
--Join sales and menu tables, then order by date and add index to them based of order_date per each customer
--Put all above into temp table, then filter it on first index

drop table if exists #row_table 
create table #row_table(
					customer_id varchar(50),
					order_date date,
					product_name varchar(50),
					row_num int
					) 
insert into #row_table (customer_id,order_date,product_name,row_num )
						select 
							sales.customer_id,
							sales.order_date,
							menu.product_name,
							ROW_NUMBER() over(partition by sales.customer_id order by order_date) as row_num
						from sales
						left join menu
						on sales.product_id = menu.product_id
						order by order_date
select * from #row_table
where row_num = 1;


--Q4
--Join menu and sales tables, then count all products and sort them
--Filter total_count on max using temp table



drop table if exists #max_purchase 
create table #max_purchase(
					product_name varchar(50),
					total_count int
					) 
insert into #max_purchase (product_name,total_count)
							select 
								menu.product_name,
								count(menu.product_name) as total_count
							from menu
							left join sales
							on menu.product_id = sales.product_id
							group by menu.product_name
							order by total_count desc
select * from #max_purchase
where total_count = (select
							max(total_count)
							from #max_purchase
					)


--Q5
--First we make temp table to add count of order per product and customer
--Then make another temp table to add maximum number of order per each customer and filter it to this number

drop table if exists #sales_menu
create table #sales_menu(
						customer_id varchar(50),
						order_date date,
						product_name varchar(50),
						price int
						)
insert into #sales_menu (customer_id, order_date, product_name, price)


							select 
								sales.customer_id,
								sales.order_date,
								menu.product_name,
								menu.price
							from sales	
							left join menu
							on sales.product_id = menu.product_id;

drop table if exists #q5
create table #q5 (
					customer_id varchar(50),
					product_name varchar(50),
					order_count int
					)
insert into #q5
			select 
			#sales_menu.customer_id as customer_id,
			#sales_menu.product_name as product_name,
			count(#sales_menu.product_name) as order_count
			from #sales_menu
			group by customer_id, product_name
		

drop table if exists #q5_1
create table #q5_1 (
					customer_id varchar(50),
					product_name varchar(50),
					order_count int,
					mx int
					)


insert into #q5_1
			select *,
					max(order_count) over(partition by customer_id) as mx
			from #q5

select 
		customer_id,
		product_name,
		order_count
		
from #q5_1
where order_count = mx

--Q6
--Joint all 3 tables
--Filter it based on grater order date than join date per customer


drop table if exists #all_table
create table #all_table
				(
				customer_id varchar(50),
				join_date date,
				product_name varchar(50),
				price int,
				order_date date
				)
insert into #all_table
			select
	#sales_menu.customer_id,
	members.join_date,
	product_name,
	price,
	order_date
from #sales_menu
left join members
on #sales_menu.customer_id = members.customer_id

drop table if exists #q6
create table #q6
			(customer_id varchar(50),
			join_date date,
			product_name varchar(50),
			price int,
			order_date date,
			row_num int
			)

insert into #q6
			select * ,
					ROW_NUMBER() over(partition by customer_id order by order_date)	as row_num	
			from #all_table
			where order_date > join_date 
			order by order_date 

select 
      customer_id,
	  order_date,
	  product_name
from #q6
where row_num = 1

--Q7
--Just opposite of Q6 steps

drop table if exists #q7
create table #q7
			(customer_id varchar(50),
			join_date date,
			product_name varchar(50),
			price int,
			order_date date,
			row_num int
			)

insert into #q7
			select * ,
					ROW_NUMBER() over(partition by customer_id order by order_date desc)	as row_num	
			from #all_table
			where order_date < join_date 
			order by order_date 

select 
      customer_id,
	  order_date,
	  product_name
from #q7
where row_num = 1


--Q8
--Use #q7 to find transaction before becoming a member then aggregate them

select 
	customer_id,
	count(product_name) as total_item,
	sum(price) as total_spent

from #q7
group by customer_id

--Q9
--Write conditional statement using product_name then sum all scores per customer

select 
        customer_id,
		sum(case
		when product_name = 'sushi' then 20
		else 10
		end * price) as total_score
from #sales_menu
group by customer_id
order by total_score desc;

--Q10
--Add another condition to Q9 case statement then filter customers and order date
select 
		customer_id ,
		sum(case
		when order_date between join_date and DATEADD(day,7,join_date) then 20
		when product_name = 'sushi' then 20
		else 10
		end * price) as total_score
from #all_table
where customer_id in ('A','B') and order_date <= '2021-01-30' 
group by customer_id
order by total_score desc;

--BQ1
--Create temp table from #all_table by setting condition on order date

drop table if exists #BQ1
create table #BQ1 (
					transaction_id int,
					customer_id varchar(50),
					order_date date,
					product_name varchar(50),
					price int,
					member varchar(50),					
					)

insert into #BQ1
			select 
					ROW_NUMBER() over(order by order_date) as transaction_id,
					customer_id,
					order_date,
					product_name,
					price,
					case
						when order_date >= join_date then 'Y'
						else 'N'
					end as member					
			from #all_table

select * from #BQ1
order by customer_id

--BQ2
--Filter null #BQ1 on Y, then rank them and join them to #BQ1
--Select needed columns from previuos temp table (#initial_BQ2)

drop table if exists #initial_BQ2
create table #initial_BQ2 (
							transaction_id int,
					customer_id varchar(50),
					order_date date,
					product_name varchar(50),
					price int,
					member varchar(50),
					transaction_id_1 int,
					ranking int,
					ranking_1 int
							)

insert into #initial_BQ2

				select
						*,
						case
							when #BQ1.member = 'N' then null
							else ranking
						end as ranking_1
				from 
				#BQ1
				left join
						(select
								transaction_id as transaction_id_1,
								RANK() over(partition by customer_id order by order_date) as ranking
						from #BQ1
						where member = 'Y') as t
				on t.transaction_id_1 = #BQ1.transaction_id

select
	customer_id,
	order_date,
	product_name,
	price,
	member,
	ranking
from #initial_BQ2
order by customer_id, order_date