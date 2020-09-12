-- query_01

with sales as
(
    select round(months_between(sale_date,to_date('01.09.2013','dd.mm.yy'))) as monh_order, manager_id, sum(sale_amount) sale_sum
    from v_fact_sale
    where  to_date(sale_date,'DD.MM.YY')  >= to_date('01.10.2013','DD.MM.YY') AND to_date(sale_date,'DD.MM.YY') < to_date('01.12.2014','DD.MM.YY')
    group by round(months_between(sale_date,to_date('01.09.2013','dd.mm.yy'))),manager_id
),
    total_sums as
(
    select sales.monh_order,manager_id ,
    sum(sales.sale_sum) over (partition by sales.manager_id order by sales.monh_order range between 3 preceding and current row) total_sum
    from sales
),
    max_sums as
(
    select total_sums.manager_id,total_sums.monh_order,total_sums.total_sum,
    max(total_sums.total_sum) over (partition by total_sums.monh_order) max_sum
    from total_sums
)
    select mngs.manager_id,mngs.manager_first_name,mngs.manager_last_name,(maxs.max_sum * 0.05) premia
    from max_sums maxs join manager mngs on maxs.manager_id = mngs.manager_id
    where maxs.total_sum = maxs.max_sum and monh_order >= 4;

--query_02

with sum_officies as
(
    select office_id, city_name, extract(YEAR from sale_date) year,country, sum(sale_amount) sum_sales
    from V_FACT_SALE
    where sale_date between to_date('01.01.2013','DD.MM.YY') and to_date('01.01.2015','DD.MM.YY')
    group by office_id,extract(YEAR from sale_date), country, city_name
),
    sum_officies_by_year as
(
    select sum_officies.office_id, sum_officies.city_name, sum_officies.year, sum_officies.country, sum_officies.sum_sales, sum(sum_officies.sum_sales) over (partition by year) total_sum
    from sum_officies
)
    select office_id, city_name, year, country, sum_sales/total_sum relative_amount
    from sum_officies_by_year
    order by relative_amount desc;

--query_03

with months as
(
    select product_id, product_name, sum(sale_amount) month_prod_qty,  trunc(MONTHS_BETWEEN(sale_date,to_date('01.12.13','DD.MM.YY'))) month_order
    from V_FACT_SALE
    where to_date(sale_date,'DD.MM.YY') >= to_date('01.12.2013','DD.MM.YY') and to_date(sale_date,'DD.MM.YY') < to_date('01.07.2014','DD.MM.YY')
    group by product_id,  trunc(MONTHS_BETWEEN(sale_date,to_date('01.12.13','DD.MM.YY'))), product_name
    order by product_id
),
    products as
(
    select months.product_id, months.product_name, months.month_order, months.month_prod_qty, LAG(months.month_prod_qty) over (partition by months.product_id order by months.month_order) as prev_qty
    from months
    order by product_id, month_order
)
    select product_id, product_name, avg(month_prod_qty/prev_qty) as speed_size
    from products
    where prev_qty is not  null
    group by product_name, product_id
    order by speed_size desc;

--query_04
with sales_in_selected_period as
(
    select sale_date,sale_amount
    from v_fact_sale
    where sale_date between to_date('01.01.2014','DD.MM.YY') and to_date('31.12.2014','DD.MM.YY')
),
    sales_by_months as
(
    select sum(sale_amount) month_sale, trunc(months_between(sale_date,to_date('01.12.13','DD.MM.YY'))) month_number
    from sales_in_selected_period
    group by  trunc(months_between(sale_date,to_date('01.12.13','DD.MM.YY')))
),
     sales_by_quartals as
(
    select sum(sale_amount) total_sum, (TO_CHAR(sale_date, 'Q') * 3) month_number
    from sales_in_selected_period
    group by TO_CHAR(sale_date, 'Q')
)
    select every_mounth.month_number,every_mounth.month_sale,
    sum(every_mounth.month_sale) over (order by every_mounth.month_number) sum_over_months,
    every_quartal.total_sum,
    sum(every_quartal.total_sum) over (order by  every_quartal.month_number nulls first)
    from sales_by_months every_mounth left join sales_by_quartals every_quartal
    on every_mounth.month_number = every_quartal.month_number
    order by every_mounth.month_number;

--query_05

with sum_sales_by_products as
         (
            select distinct product_id, product_name, sum(sale_amount) over (partition by product_id) sum_sales
            from v_fact_sale
            where sale_date between to_date('01.01.2014','DD.MM.YY') and to_date('31.12.2014','DD.MM.YY')
         ),
      sum_sales_with_row_numbers as
          (
            select product_id,product_name, sum_sales,  percent_rank() over (order by sum_sales desc) percent
            from sum_sales_by_products
          )
            select product_id,product_name, sum_sales, round(percent,2) round_percent
            from sum_sales_with_row_numbers
            where round(percent,2) <= 0.1 or round(percent,2)>=0.9;


--query_06

with managers_sales as
    (
        select manager_id, manager_last_name, manager_first_name, country, sale_date, sale_qty,
        SUM(sale_qty) over (partition by country,manager_id order by sale_qty) country_sale_qty
        from v_fact_sale
        where sale_date between to_date('01.01.2014','DD.MM.YY') and to_date('31.12.2014','DD.MM.YY')
        order by country
    ),
    maximum as
    (
        select distinct last_value(country_sale_qty ) over (partition by country, manager_id) manager_sum,
        manager_id, manager_last_name, manager_first_name, country
        from managers_sales
    ),
    sum_managers_sales as
    (
        select manager_sum, manager_id, manager_last_name, manager_first_name, country,
                rank() over (partition by country order by manager_sum) rank_id
        from maximum
    )
        select country, manager_last_name|| ' , ' ||manager_first_name name
        from sum_managers_sales
        where rank_id in (1,2,3);

--query_07
with sales_by_months as
         (
             select distinct product_id,
                             product_name,
                             sale_amount,
                             trunc(MONTHS_BETWEEN(sale_date, to_date('01.12.13', 'DD.MM.YY'))) month_order
             from v_fact_sale
             where sale_date between to_date('01.01.2014', 'DD.MM.YY') and to_date('31.12.2014', 'DD.MM.YY')
         ),
     sales_by_months_sums as
         (
             select distinct product_id,product_name, month_order, sum(sale_amount) over (partition by product_id, month_order) sum_sales_in_months
             from sales_by_months
         ),
    max_mins as
        (
            select product_id,product_name, month_order,sum_sales_in_months, max(sum_sales_in_months) over ( partition by month_order) maximum,
                    min(sum_sales_in_months) over ( partition by month_order) minimum
            from sales_by_months_sums
        ),
    max_sales as
         (
             select product_id expensive_product_id, product_name expensive_product_name, month_order, sum_sales_in_months expensive_price
             from max_mins
             where sum_sales_in_months = maximum
         ),
     min_sales as
         (
             select product_id cheapest_product_id, product_name cheapest_product_name, month_order, sum_sales_in_months cheapest_price
             from max_mins
             where sum_sales_in_months = minimum
         )
        select cheapest_product_id, cheapest_product_name, expensive_product_id,expensive_product_name,max_sales.month_order month, cheapest_price, expensive_price
        from max_sales join min_sales on max_sales.month_order= min_sales.month_order;


--query_08

with salary as
        (
            select sum(sale_amount) over (partition by trunc(MONTHS_BETWEEN(sale_date,to_date('01.12.13','DD.MM.YY')))) total_sales,
            manager_id,
            trunc(MONTHS_BETWEEN(sale_date,to_date('01.12.13','DD.MM.YY'))) month_order,
            (round(sum(sale_amount) over (partition by manager_id, trunc(MONTHS_BETWEEN(sale_date,to_date('01.12.13','DD.MM.YY'))))/1.1,2)) first_price,
            30000+0.05*sum(sale_amount) over (partition by manager_id, trunc(MONTHS_BETWEEN(sale_date,to_date('01.12.13','DD.MM.YY'))) ) manager_income
            from V_FACT_SALE
            where  sale_date between to_date('01.01.2014', 'DD.MM.YY') and to_date('31.12.2014', 'DD.MM.YY')
        ),
     sum_salary as
         (
            select distinct total_sales, sum(first_price) first_price_total, month_order, sum(manager_income) salary_amount
            from salary
            group by month_order,total_sales
            order by month_order
        )
            select  first_price_total, salary_amount, month_order, total_sales - (first_price_total +salary_amount) profit
            from sum_salary;