-- ------------------------------------------------------------------------
-- Script:  04.7_add_sort_columns_dim_date.sql
-- Purpose: Add sort columns to mart.dim_date to support correct
--          chronological ordering in Power BI slicers
--          quarter_sort: enables Q1 2024, Q2 2024... Q1 2025 ordering
-- ------------------------------------------------------------------------

-- add quarter sort column
alter table mart.dim_date
add quarter_sort int;

-- populate: year * 100 + quarter gives 202401, 202402... 202501
update mart.dim_date
set quarter_sort = year_num * 100 + quarter_num;

-- verify
select 
    quarter_name,
    quarter_sort
from mart.dim_date
group by quarter_name, quarter_sort
order by quarter_sort;