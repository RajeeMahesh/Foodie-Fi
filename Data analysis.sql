2.What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select sum(case when extract(month from start_date) = 1 then 1 
			else 0 end) as Jan,
       sum(case when extract(month from start_date) = 2 then 1 
			else 0 end) as Feb,
       sum(case when extract(month from start_date) = 3 then 1 
			else 0 end) as March,
       sum(case when extract(month from start_date) = 4 then 1 
			else 0 end) as April,
       sum(case when extract(month from start_date) = 5 then 1 
			else 0 end) as May,
       sum(case when extract(month from start_date) = 6 then 1 
			else 0 end) as June, 
       sum(case when extract(month from start_date) = 7 then 1 
			else 0 end) as July,
       sum(case when extract(month from start_date) = 8 then 1 
			else 0 end) as Aug,
       sum(case when extract(month from start_date) = 9 then 1 
			else 0 end) as Sept, 
       sum(case when extract(month from start_date) = 10 then 1 
			else 0 end) as Oct,
       sum(case when extract(month from start_date) = 11 then 1 
			else 0 end) as Nov,
       sum(case when extract(month from start_date) = 12 then 1 
			else 0 end) as Dece
from foodie_fi.subscriptions
where plan_id = 0

3.What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select plan_name, count(plan_name) as count
from foodie_fi.subscriptions s
join foodie_fi.plans p
on s.plan_id = p.plan_id
where extract(year from start_date) > 2020
group by plan_name, p.plan_id 
order by p.plan_id

o/p : **Schema (PostgreSQL v13)**

| plan_name     | count |
| ------------- | ----- |
| basic monthly | 8     |
| pro monthly   | 60    |
| pro annual    | 63    |
| churn         | 71    |

---

[View on DB Fiddle](https://www.db-fiddle.com/f/rHJhRrXy5hbVBNJ6F6b9gJ/16)
From the output we can infer that there are new subscriptions in the year 2021 and many people opted out Foodie_fi in 2021.

4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select sum, count, round(percentage,1)
from 
      (select sum (case when plan_id = 4 then 1 else 0 end) as sum, count(distinct customer_id) as count,
            ((sum (case when plan_id = 4 then 1 else 0 end)*100)/
            count(distinct customer_id)) as percentage
      from f.subscriptions) t1
      
5.How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
select 
((select count(customer_id) as churned_after_trial
from 
      (select customer_id, plan_id, row_number() over (partition by customer_id
                               order by plan_id) as row_order
      from f.subscriptions) t1 
where plan_id = 4 and row_order = 2)*100)/(select count(distinct customer_id) from f.subscriptions)

6.What is the number and percentage of customer plans after their initial free trial?
select *, concat(((count_plan*100)/count_tot),'%') as perc
from 
      (select *, 
            (select count(distinct customer_id) from f.subscriptions) as count_tot
      from 
            (select p.plan_id, plan_name, count(plan_name) as count_plan
            from
            (select customer_id, plan_id, row_number() over (partition by customer_id
                                               order by plan_id) as row_order
                      from f.subscriptions) t1
            join f.plans p 
            on t1.plan_id = p.plan_id
            where row_order = 2
            group by p.plan_id, plan_name
            order by p.plan_id) t2) t3
	  
7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

select *, concat((plan_count*100)/tot_count,'%') as Perc_split
from 
      (select *, (select count(distinct customer_id) 
                              from f.subscriptions 
                              where start_date < '2021-01-01') as tot_count
      from            
            (select t1.plan_id, plan_name, count(plan_name) as plan_count
            from
                (select customer_id, plan_id, start_date, row_number() over (partition by customer_id
                                                                          order by plan_id desc
                                                                          ) as row_order
                from f.subscriptions
                where start_date < '2021-01-01') t1
            join f.plans p 
            on p.plan_id = t1.plan_id
            where row_order = 1 
            group by t1.plan_id, plan_name) t2)t3
	    
8.How many customers have upgraded to an annual plan in 2020?
select count(plan_id) as no_of_cust_upgraded_to_annualplan
from
    (select customer_id, plan_id, start_date, row_number() over (partition by customer_id
                                                                              order by plan_id desc
                                                                              ) as row_order
    from f.subscriptions
    where start_date < '2021-01-01')t1
where row_order = 1 and plan_id =3 

9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
select round(avg(gap),2) as avg_days_took_to_switch
from 
        (select t1.customer_id, min, max, s1.start_date, s.start_date as switch_date, (s.start_date-s1.start_date) as gap
        from
              (select customer_id, min(plan_id) as min, max(plan_id) as max
              from f.subscriptions 
              group by customer_id
              having max(plan_id) = 3
              order by customer_id)t1
        join f.subscriptions s 
        on t1.customer_id = s.customer_id and t1.max = s.plan_id
        join f.subscriptions s1
        on t1.customer_id = s1.customer_id and t1.min = s1.plan_id) t2
	
10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
select categ, count(gap), round(avg(gap),2) as avg_cust_switchedto_plan3
from
        (select customer_id, min, max, gap, (case when gap <= 30 then 'A-0-30'
                        when gap <= 60 then 'B-3-1-60'
                        when gap <= 90 then 'C-61-90'
                        when gap <= 120 then 'D-91-120'
                        when gap <= 150 then 'E-121-150'
                        when gap <= 180 then 'F-151-180'
                        when gap <= 210 then 'G-181-210'
                        when gap <= 240 then 'H-211-240'
                        when gap <= 270 then 'I-241-270'
                        when gap <= 300 then 'J-271-300'
                        when gap <= 330 then 'K-301-330'
                        when gap <= 360 then 'L-331-360'
                        when gap <= 390 then 'M-361-390'
                   end) as categ
        from 
              (select t1.customer_id, min, max, s1.start_date, s.start_date as switch_date, (s.start_date-s1.start_date) as gap
                      from
                            (select customer_id, min(plan_id) as min, max(plan_id) as max
                            from f.subscriptions 
                            group by customer_id
                            having max(plan_id) = 3
                            order by customer_id)t1
                      join f.subscriptions s 
                      on t1.customer_id = s.customer_id and t1.max = s.plan_id
                      join f.subscriptions s1
                      on t1.customer_id = s1.customer_id and t1.min = s1.plan_id) t2) t3
group by categ
order by categ

11.How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
select *
        from
              (select customer_id, plan_id, start_date, row_number() over (partition by customer_id
                                                                                            order by start_date
                                                                                            ) as row_order
              from f.subscriptions
              where start_date < '2021-01-01')t1
        where row_order = 3 and plan_id = 1
	
/* This gives no rows, and so we dont have any customer who downgraded from promonthly to basic plan */