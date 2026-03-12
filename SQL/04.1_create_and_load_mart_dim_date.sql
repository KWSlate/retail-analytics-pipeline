-- ------------------------------------------------------------------------
-- Script:  04.1_create_and_load_mart_dim_date.sql
-- Purpose: Create and populate mart date dimension
--          Direct copy from silver.dim_date with mart naming conventions
-- ------------------------------------------------------------------------

-- drop and create mart.dim_date
drop table if exists mart.dim_date;
create table mart.dim_date (
    date_key         int identity(1,1) primary key,
    date             date,
    day_of_week_num  int,           -- 1=Sunday, 2=Monday ... 7=Saturday
    day_name         varchar(10),   -- Sunday, Monday etc.
    day_abbr         varchar(3),    -- Sun, Mon etc.
    week_start_date  date,          -- Sunday of the week this date belongs to
    week_of_year     int,           -- 1-53
    week_num_overall int,           -- sequential week number across full range
    month_num        int,           -- 1-12
    month_name       varchar(10),   -- January, February etc.
    month_abbr       varchar(3),    -- Jan, Feb etc.
    quarter_num      int,           -- 1-4
    quarter_name     varchar(7),    -- Q1 2024 etc.
    year_num         int,           -- 2024, 2025
    weekend_flag     bit,           -- 1=Saturday or Sunday, 0=weekday
    date_created     datetime2(3)
);

-- populate from silver.dim_date
insert into mart.dim_date (date, day_of_week_num, day_name, day_abbr, week_start_date, week_of_year, week_num_overall, month_num, 
                            month_name, month_abbr, quarter_num, quarter_name, year_num, weekend_flag, date_created)
select
    date, day_of_week_num, day_name, day_abbr, week_start_date, week_of_year, week_num_overall,
    month_num, month_name, month_abbr, quarter_num, quarter_name, year_num, weekend_flag, sysdatetime()
from silver.dim_date;

-- verification
select
    count(*)             as total_days,
    min(date)            as first_date,
    max(date)            as last_date
from mart.dim_date;