/*

Which month has the highest count of valid users created?
A valid user is defined as:
Has a Non-Block email address
Has User ID
Neither the first name nor last name includes “test”


*/

--Question 1
with highest_month as (
	select
		count(b.user_id) as valid_users,
		date_trunc('month', create_date) as month
	from public.block_user b
	inner join public.email e
		on b.user_id = e.user_id
	inner join public.contact c
		on b.user_id = c.user_id
	where hashed_email not like '%@blockrenovation.com%'
		and (first_name <> 'test' or last_name <> 'test')
	group by date_trunc('month', create_date)
	order by 1 desc
	limit 1
)
select * from highest_month;

--Question 2
--Which month brought in the highest gross deal value?

select count(*), deal_id from public.deal --this query checks if there are duplicate deal_ids in the source table
group by 2
having count(*) > 1;

select * from public.deal --this query checks if there are any deal_ids that are null
where deal_id is null;



with highest_month as (
select 
	date_trunc('month',closed_won_date) as month,
	sum(deal_value_usd) as monthly_gross_deal_value
from public.deal
	where closed_won_date is not null 
	and deal_value_usd is not null
group by 1
order by 2 desc
limit 1
)
select * from highest_month;

--Question 3
/*
 What percentage of “closed won” deals does each city account for?
We’ll define a “close won” deal as one that:
Has an assigned closed, won date
Has a valid user (use same criteria as question #1)
 */


with get_contact_id as (
select
	d.deal_id,
	dc.contact_id
from public.deal d
inner join public.deal_contact dc
	on d.deal_id = dc.deal_id 
where closed_won_date is not null
),

get_location as (
select
	c.user_id,
	property_city
from public.contact c 
inner join public.email e
	on c.user_id  = e.user_id 
where hashed_email not like '%@blockrenovation.com%'
	and (first_name <> 'test' or last_name <> 'test')
	and property_city is not null
),

final as (
select
	property_city,
	count(*) * 100.0/ sum(count(*)) over () as city_percent
from get_location
group by 1 
)
select * from final
order by 2 desc
	

--Final Question
/*
How much quarterly business has each Source generated for Block? 
Which sources are performing above or below their historical monthly benchmarks?
*/

select distinct property_utm_source from public.contact 
--Used this query to check total number of sources before excluding test data


select * from public.deal
where closed_won_date between '2021-07-01' and '2021-09-30'
order by 4 desc;
--Used this query to make note of lastest won date entered

select max(closed_won_date) from public.deal; 
--Used this query to make note of lastest won date entered


--
--

with get_properties as (
select
	d.deal_value_usd,
	d.closed_won_date,
	dc.contact_id
from deal d
inner join deal_contact dc 
	on d.deal_id = dc.deal_id
where deal_value_usd is not null
),

join_with_contacts as (
select
	c.property_utm_source,
	date_trunc('quarter',closed_won_date) as quarter,
	sum(deal_value_usd) as quarterly_value
from get_properties gp
inner join contact c 
	on gp.contact_id = c.contact_id 
where property_utm_source is not null
and (first_name <> 'test' or last_name <> 'test')
group by 1, date_trunc('quarter',closed_won_date)
order by 1,2
),

final as (		
select 
property_utm_source as source,
quarter,
quarterly_value,
(quarterly_value - lag(quarterly_value,1) over (partition by property_utm_source order by quarter))/lag(quarterly_value,1) over (partition by property_utm_source order by quarter) * 100 as percent_change
from join_with_contacts
)

select * from final;