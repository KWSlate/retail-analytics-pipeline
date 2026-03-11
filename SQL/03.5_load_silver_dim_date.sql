-- ------------------------------------------------------------------------
-- Script:  03.5_load_silver_dim_date.sql
-- Purpose: Create and populate silver date dimension
--          Date range: 2024-04-01 through 2025-05-31
--          Week starts on Sunday
-- ------------------------------------------------------------------------

-- drop and create dim_date
drop table if exists silver.dim_date;
create table silver.dim_date (
    id                int identity(1,1) primary key,
    date              date,
    day_of_week_num   int,           -- 1=Sunday, 2=Monday ... 7=Saturday
    day_name          varchar(10),   -- Sunday, Monday etc.
    day_abbr          varchar(3),    -- Sun, Mon etc.
    week_start_date   date,          -- Sunday of the week this date belongs to
    week_of_year      int,           -- 1-53
    week_num_overall  int,           -- sequential week number across full range
    month_num         int,           -- 1-12
    month_name        varchar(10),   -- January, February etc.
    month_abbr        varchar(3),    -- Jan, Feb etc.
    quarter_num       int,           -- 1-4
    quarter_name      varchar(7),    -- Q1 2024 etc.
    year_num          int,           -- 2024, 2025
    weekend_flag      bit,           -- 1=Saturday or Sunday, 0=weekday
    date_created      datetime2(3)
);

-- populate dim_date using recursive CTE to generate date series
with date_series as (
    -- anchor: start date
    select cast('2024-04-01' as date) as date
    union all
    -- recursive: add one day at a time
    select dateadd(day, 1, date)
    from date_series
    where date < '2025-05-31'
)
insert into silver.dim_date (date, day_of_week_num, day_name, day_abbr, week_start_date, week_of_year, week_num_overall,
                            month_num, month_name, month_abbr, quarter_num, quarter_name, year_num, weekend_flag, date_created)
select
    date,
    -- day of week: 1=Sunday through 7=Saturday
    datepart(weekday, date)                                         as day_of_week_num,
    datename(weekday, date)                                         as day_name,
    left(datename(weekday, date), 3)                                as day_abbr,
    -- week start = most recent Sunday
    dateadd(day, -(datepart(weekday, date) - 1), date)              as week_start_date,
    -- week of year starting Sunday
    datepart(week, date)                                            as week_of_year,
    -- sequential week number from start of date range
    datediff(week, dateadd(day, -(datepart(weekday,'2024-04-01')-1),
             '2024-04-01'), 
             dateadd(day, -(datepart(weekday, date)-1), date)) + 1  as week_num_overall,
    month(date)                                                     as month_num,
    datename(month, date)                                           as month_name,
    left(datename(month, date), 3)                                  as month_abbr,
    datepart(quarter, date)                                         as quarter_num,
    concat('Q', datepart(quarter, date), ' ', year(date))           as quarter_name,
    year(date)                                                      as year_num,
    case when datepart(weekday, date) in (1, 7) then 1 else 0 end   as weekend_flag,
    sysdatetime()
from date_series
option (maxrecursion 500);  -- default is 100, need higher for 425 days

-- verification
select 
    count(*)        as total_days,
    min(date)       as first_date,
    max(date)       as last_date,
    count(distinct week_start_date)  as total_weeks,
    count(distinct month_num + year_num * 100) as total_months
from silver.dim_date;