-- dominos case study 

select * from order_details;
select * from orders;
select * from pizza;
select * from pizza_type; 

-- --------------------------------------------------------------------------------------------------------------------------------------------
-- 1. Retrive the total number of orders placed
SELECT 
    COUNT(order_id)
FROM
    orders;

-- --------------------------------------------------------------------------------------------------------------------------------------------

-- 2.Calculate the total revenue generated from pizza sales.
SELECT 
    ROUND(SUM(p.price * o.quantity), 2) AS Totalrevenue
FROM
    pizza p
        JOIN
    order_details o ON p.pizza_id = o.pizza_id;

-- --------------------------------------------------------------------------------------------------------------------------------------------

-- 3.Identify the highest-priced pizza.
with temp as (select pt.name,price from pizza p join pizza_type pt on p.pizza_type = pt.pizza_type)
SELECT 
    name, price
FROM
    temp
ORDER BY price DESC
LIMIT 1;

-- --------------------------------------------------------------------------------------------------------------------------------------------

-- 4.Identify the most common pizza size ordered.

SELECT 
    p.size, COUNT(od.order_id) total
FROM
    pizza p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
GROUP BY p.size
ORDER BY total DESC
LIMIT 1;

-- -------------------------------------------------------------------------------------------------------------------------------------------

-- 5.List the top 5 most ordered pizza types along with their quantities.

SELECT 
    pt.name, COUNT(od.quantity) AS quantity
FROM
    pizza p
        JOIN
    order_details od ON p.pizza_id = od.pizza_id
        JOIN
    pizza_type pt ON pt.pizza_type = p.pizza_type
GROUP BY pt.name
ORDER BY quantity DESC
LIMIT 5;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 6.Join the necessary tables to find the total quantity of each pizza category ordered.
SELECT 
    pt.category, COUNT(od.quantity) AS quantity
FROM
    pizza_type pt
        JOIN
    pizza p ON pt.pizza_type = p.pizza_type
        JOIN
    order_details od ON od.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY quantity DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------------

--  7.Determine the distribution of orders by hour of the day.

SELECT 
    HOUR(time) AS hour, COUNT(order_id) AS ordersplaced
FROM
    orders
GROUP BY HOUR(time)
ORDER BY ordersplaced DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 8.Find the category-wise distribution of pizzas.
select pt.category, count(name) from pizza_type pt group by category;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 9. Calculate the average number of pizzas ordered per day
SELECT 
    ROUND(AVG(quantity), 0) AS avg_quantity
FROM
    (SELECT 
        o.date, COUNT(od.quantity) AS quantity
    FROM
        orders o
    JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.date) AS temp;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 10. Determine the top 3 most ordered pizza types based on revenue.

SELECT 
    pt.name, SUM((p.price * od.quantity)) AS revenue
FROM
    order_details od
        JOIN
    pizza p ON p.pizza_id = od.pizza_id
        JOIN
    pizza_type pt ON pt.pizza_type = p.pizza_type
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 11. Calculate the percentage contribution of each pizza type to total revenue. 
SELECT 
    pt.category,
    ROUND(((SUM((od.quantity * p.price)) / (SELECT 
                    SUM(od.quantity * p.price) AS totalsales
                FROM
                    order_details od
                        JOIN
                    pizza p ON od.pizza_id = p.pizza_id)) * 100),
            2) AS revenue
FROM
    order_details od
        JOIN
    pizza p ON od.pizza_id = p.pizza_id
        JOIN
    pizza_type pt ON pt.pizza_type = p.pizza_type
GROUP BY pt.category;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 12. Analyze the cumulative revenue generated over time.

SELECT date,sum(revenue) OVER(ORDER BY date) AS cumulative_revenue 
FROM
 (SELECT 
    o.date, SUM(od.quantity * p.price) AS revenue
FROM
    order_details od
        JOIN
    pizza p ON od.pizza_id = p.pizza_id
        JOIN
    orders o ON o.order_id = od.order_id
GROUP BY o.date) AS temp;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 13. Determine the top 3 most ordered pizza types based on revenue for each pizza category.
with idk as (select category,name,revenue, rank() over(partition by category order by revenue desc) as rn from 
(select pt.category, pt.name, sum(od.quantity * p.price) as revenue from order_details od join pizza p on od.pizza_id = p.pizza_id
join pizza_type pt on pt.pizza_type = p.pizza_type group by pt.category,pt.name) as temp )
select category,name,revenue from idk where rn<=3;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 14. Identify peak ordering days
SELECT 
    DAYNAME(date) AS day, COUNT(order_id) AS orderplaced
FROM
    orders
GROUP BY DAYNAME(date)
ORDER BY orderplaced DESC
LIMIT 3;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 15.Find the most popular pizza category for each size 
with idk as (select category,size,totalcount, rank() over(partition by category order by totalcount desc) as rn 
from (select pt.category, p.size , sum(od.quantity) as totalcount 
from pizza_type pt join pizza p on pt.pizza_type = p.pizza_type 
join order_details od on od.pizza_id = p.pizza_id group by pt.category,p.size) as temp)
select category,size,totalcount from idk where rn=1;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 16. Compare order trends over months
select monthname(o.date), round(sum(p.price * od.quantity),0) as revenue from orders o join order_details od on o.order_id = od.order_id 
join pizza p on p.pizza_id = od.pizza_id group by monthname(o.date) ;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 17. Calculate Month-on-Month (MoM) Revenue Change with Percentage Analysis
select month,revenue, concat(round(((revenue-previous)/previous)*100,1),'%') as MoM_Percentage from (
with idk as (select monthname(o.date) as month, round(sum(p.price * od.quantity),0) as revenue from orders o join order_details od on o.order_id = od.order_id 
join pizza p on p.pizza_id = od.pizza_id group by monthname(o.date))
select month,revenue, lag(revenue,1) over(order by month(month)) as previous from idk
) t;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 18. Find out how often different pizza categories are ordered together in the same order.
SELECT 
    pt1.category AS category1,
    pt2.category AS category2,
    COUNT(DISTINCT od1.order_id) AS totalcount
FROM
    order_details od1
        JOIN
    order_details od2 ON od1.order_id = od2.order_id
        AND od1.pizza_id != od2.pizza_id
        JOIN
    pizza p1 ON od1.pizza_id = p1.pizza_id
        JOIN
    pizza p2 ON od2.pizza_id = p2.pizza_id
        JOIN
    pizza_type pt1 ON pt1.pizza_type = p1.pizza_type
        JOIN
    pizza_type pt2 ON pt2.pizza_type = p2.pizza_type
WHERE
    pt1.category <= pt2.category
GROUP BY pt1.category , pt2.category
ORDER BY totalcount DESC;

-- ------------------------------------------------------------------------------------------------------------------------------------------

-- 19. Determine the most popular pizza types during different time slots
select time_slot,name,totalorders from (
select 
case 
	when hour(o.time) between 6 and 11 then 'Morning'
    when hour(o.time) between 12 and 15 then 'Afternoon'
    when hour(o.time) between 16 and 19 then 'Evening'
    else 'Late Night'
    end as time_slot,
    rank() over(partition by 
    case 
	when hour(o.time) between 6 and 11 then 'Morning'
    when hour(o.time) between 12 and 15 then 'Afternoon'
    when hour(o.time) between 16 and 19 then 'Evening'
    else 'Late Night'
    end
    order by count(od.order_id) desc
    ) as rn,
pt.name, count(od.order_id) as totalorders 
from order_details od join orders o on od.order_id = o.order_id 
join pizza p on od.pizza_id = p.pizza_id 
join pizza_type pt on pt.pizza_type = p.pizza_type
group by time_slot,pt.name
) t where rn = 1
order by field(time_slot,'Morning','Afternoon','Evening','Late Night');




 