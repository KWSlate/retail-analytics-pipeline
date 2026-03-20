-- ------------------------------------------------------------------------
-- Script:  04.7_load_mart_dim_month.sql
-- Purpose: Create month-grain dimension table to support Power BI
--          relationships between daily dim_date and monthly fact tables.
--
-- Design decision: mart.fact_sales_monthly aggregates to monthly grain
--          (store x product x month), breaking the standard date_key
--          relationship to mart.dim_date (daily grain). This bridge
--          dimension provides a clean one-to-many join at monthly grain,
--          eliminating many-to-many relationship issues in Power BI.
--          Sourced from mart.dim_date to ensure consistency of all
--          date attributes.
-- ------------------------------------------------------------------------
drop table if exists mart.dim_month;
create table mart.dim_month (
    month_sort   int          primary key,  -- YYYYMM e.g. 202405
    year_num     int,
    month_num    int,
    month_name   varchar(10),
    month_abbr   varchar(3),
    quarter_num  int,
    quarter_name varchar(7),
    quarter_sort int                        -- YYYYQ  e.g. 20242
);

insert into mart.dim_month (
    month_sort,
    year_num,
    month_num,
    month_name,
    month_abbr,
    quarter_num,
    quarter_name,
    quarter_sort
)
select distinct
    year_num * 100 + month_num  as month_sort,
    year_num,
    month_num,
    month_name,
    month_abbr,
    quarter_num,
    quarter_name,
    year_num * 10  + quarter_num as quarter_sort
from mart.dim_date
order by month_sort;

-- ------------------------------------------------------------------------
-- verification
-- ------------------------------------------------------------------------
select
    count(*)                as total_rows,
    min(month_sort)         as first_month,
    max(month_sort)         as last_month,
    count(distinct year_num) as distinct_years,
    count(distinct month_num) as distinct_months
from mart.dim_month;