-- ------------------------------------------------------------------------
-- Script:  04.6a_load_mart_fact_sales_monthly.sql
-- Purpose: Create monthly aggregated fact table to support Power BI
--          Import mode with full store and product dimension slicing.
--
-- Design decision: Source data is daily grain (112,185,566 rows).
--          Aggregated to monthly grain to support Power BI Import mode
--          performance while retaining full store and product dimension
--          attributes for slicing.
--          Daily grain fact table (mart.fact_sales) retained in mart
--          for any future DirectQuery or detailed analysis needs.
--
-- Change log:
--   - Added month_sort, quarter_sort fields for Power BI axis sorting
--   - Filtered to rolling 12-month window: May 2024 – Apr 2025
-- ------------------------------------------------------------------------
drop table if exists mart.fact_sales_monthly;
create table mart.fact_sales_monthly (
    id             int identity(1,1) primary key,
    year_num       int,
    month_num      int,
    month_name     varchar(10),
    month_abbr     varchar(3),
    month_sort     int,              -- YYYYMM for cross-year sort
    quarter_num    int,
    quarter_name   varchar(7),
    quarter_sort   int,              -- YYYYQ for cross-year sort
    store_key      int,
    product_key    int,
    total_sales    decimal(18,4),
    total_sales_py decimal(18,4),
    total_qty      decimal(18,4),
    total_qty_py   decimal(18,4),
    date_created   datetime2(3)
);

insert into mart.fact_sales_monthly (year_num, month_num, month_name, month_abbr, month_sort,
                                    quarter_num, quarter_name, quarter_sort, store_key, product_key,
                                    total_sales, total_sales_py, total_qty, total_qty_py, date_created)
select
    d.year_num,
    d.month_num,
    d.month_name,
    d.month_abbr,
    (d.year_num * 100) + d.month_num          as month_sort,   -- e.g. 202405
    d.quarter_num,
    d.quarter_name,
    (d.year_num * 100)  + d.quarter_num        as quarter_sort, -- e.g. 202402
    f.store_key,
    f.product_key,
    sum(f.sales)                              as total_sales,
    sum(f.sales_py)                           as total_sales_py,
    sum(f.qty)                                as total_qty,
    sum(f.qty_py)                             as total_qty_py,
    sysdatetime()
from mart.fact_sales f
    inner join mart.dim_date d on f.date_key = d.date_key
        where d.year_num * 100 + d.month_num >= 202405 and d.year_num * 100 + d.month_num <= 202504
group by
    d.year_num,
    d.month_num,
    d.month_name,
    d.month_abbr,
    d.quarter_num,
    d.quarter_name,
    f.store_key,
    f.product_key;

-- ------------------------------------------------------------------------
-- verification
-- ------------------------------------------------------------------------
select
    count(*)                                        as total_rows,
    count(distinct store_key)                       as stores,
    count(distinct product_key)                     as products,
    count(distinct year_num * 100 + month_num)      as months,       -- expect 12
    min(cast(year_num as varchar) + '-' +
        right('0' + cast(month_num as varchar), 2)) as first_month,  -- expect 2024-05
    max(cast(year_num as varchar) + '-' +
        right('0' + cast(month_num as varchar), 2)) as last_month,   -- expect 2025-04
    min(month_sort)                                 as min_month_sort,
    max(month_sort)                                 as max_month_sort,
    min(quarter_sort)                               as min_quarter_sort,
    max(quarter_sort)                               as max_quarter_sort
from mart.fact_sales_monthly;