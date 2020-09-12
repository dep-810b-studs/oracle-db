SELECT * FROM sales_order;

SELECT * FROM sales_order WHERE ORDER_DATE > to_date('01-01-2016','DD-MM-YYYY');

SELECT * FROM sales_order WHERE ORDER_DATE > to_date('01-01-2016','DD-MM-YYYY')
                            AND ORDER_DATE < to_date('15-07-2016','DD-MM-YYYY');

SELECT * FROM manager WHERE MANAGER_FIRST_NAME = 'Henry';

SELECT * FROM manager, sales_order 
    WHERE manager.manager_id = sales_order.manager_id 
    AND MANAGER_FIRST_NAME = 'Henry';

SELECT DISTINCT country
    FROM CITY;

SELECT DISTINCT country, region
    FROM CITY;

SELECT COUNT(region), country
    FROM CITY
    GROUP BY country;

SELECT sale_qty 
    FROM mv_fact_sale 
    WHERE sale_date BETWEEN to_date('01-01-2016','DD-MM-YYYY') AND to_date('30-01-2016','DD-MM-YYYY');

SELECT region FROM CITY
	UNION SELECT country FROM CITY
    UNION SELECT city_name FROM CITY;

with managers as (select manager_first_name,manager_last_name ,sum(product_price*product_qty) price
from manager man join sales_order sale on man.manager_id = sale.manager_id
join sales_order_line orderline on sale.sales_order_id = orderline.sales_order_id
where order_date >= to_date('01/01/2016','DD.MM.YYYY') 
       AND order_date <= to_date('31/01/2016','DD.MM.YYYY')
group by man.manager_id,manager_first_name,manager_last_name)
select manager_first_name,manager_last_name
from (select max(price) max_price from managers) maximum, managers
where managers.price = maximum.max_price;