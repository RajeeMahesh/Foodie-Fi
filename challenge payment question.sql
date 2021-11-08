The Foodie-Fi team wants to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
once a customer churns they will no longer make payments

select *, 
		(case when lag_price = 9.90 then price-lag_price
        else price
        end) corrected_price
from 
      (select customer_id, s.plan_id, row_number() over (partition by customer_id
                                                        order by start_date) as orders, 
              start_date, plan_name, price, lag(price) over (partition by customer_id) as lag_price
      from f.subscriptions s 
      join f.plans p 
      on p.plan_id = s.plan_id
      where s.plan_id <> 0 and s.plan_id <> 4) t1