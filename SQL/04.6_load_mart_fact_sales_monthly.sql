-- ------------------------------------------------------------------------
-- Script:  04.6_load_mart_fact_sales_monthly.sql
-- Purpose: Create monthly aggregated fact table to support Power BI
--          Import mode with full store and product dimension slicing.
--
-- Design decision: Source data is daily grain (112,185,566 rows).
--          Aggregated to monthly grain (5,753,797 rows) to support
--          Power BI Import mode performance while retaining full
--          store and product dimension attributes for slicing.
--          Daily grain fact table (mart.fact_sales) retained in mart
--          for any future DirectQuery or detailed analysis needs.
-- ------------------------------------------------------------------------

drop table if exists mart.fact_sales_monthly;
create table mart.fact_sales_monthly (
    id             int identity(1,1) primary key,
    year_num       int,
    month_num      int,
    month_name     varchar(10),
    month_abbr     varchar(3),
    quarter_num    int,
    quarter_name   varchar(7),
    store_key      int,
    product_key    int,
    total_sales    decimal(18,4),
    total_sales_py decimal(18,4),
    total_qty      decimal(18,4),
    total_qty_py   decimal(18,4),
    date_created   datetime2(3)
);

insert into mart.fact_sales_monthly (
    year_num, month_num, month_name, month_abbr, quarter_num, quarter_name, store_key, 
    product_key, total_sales, total_sales_py, total_qty, total_qty_py, date_created
)
select
    dim_date.year_num,
    dim_date.month_num,
    dim_date.month_name,
    dim_date.month_abbr,
    dim_date.quarter_num,
    dim_date.quarter_name,
    fact_sales.store_key,
    fact_sales.product_key,
    sum(fact_sales.sales)       as total_sales,
    sum(fact_sales.sales_py)    as total_sales_py,
    sum(fact_sales.qty)         as total_qty,
    sum(fact_sales.qty_py)      as total_qty_py,
    sysdatetime()
from mart.fact_sales fact_sales
inner join mart.dim_date dim_date
    on fact_sales.date_key = dim_date.date_key
group by
    dim_date.year_num,
    dim_date.month_num,
    dim_date.month_name,
    dim_date.month_abbr,
    dim_date.quarter_num,
    dim_date.quarter_name,
    fact_sales.store_key,
    fact_sales.product_key;

-- ------------------------------------------------------------------------
-- verification
-- ------------------------------------------------------------------------
select
    count(*)                                        as total_rows,
    count(distinct store_key)                       as stores,
    count(distinct product_key)                     as products,
    count(distinct year_num * 100 + month_num)      as months,
    min(cast(year_num as varchar) + '-' + 
        right('0' + cast(month_num as varchar), 2)) as first_month,
    max(cast(year_num as varchar) + '-' + 
        right('0' + cast(month_num as varchar), 2)) as last_month
from mart.fact_sales_monthly;

-- add date_key to fact_sales_monthly
alter table mart.fact_sales_monthly
add date_key int;

-- populate from dim_date matching year and month
update mart.fact_sales_monthly
set date_key = dim_date.date_key
from mart.fact_sales_monthly
inner join mart.dim_date
    on fact_sales_monthly.year_num = dim_date.year_num
    and fact_sales_monthly.month_num = dim_date.month_num
    and dim_date.date = dateadd(day, 1 - day(dim_date.date), dim_date.date);

-- verify
select count(*) as total, count(date_key) as with_date_key 
from mart.fact_sales_monthly;
