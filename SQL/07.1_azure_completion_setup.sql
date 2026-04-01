-- =============================================================================
-- File:    07.1_azure_completion_setup.sql
-- Purpose: Complete Azure mart layer setup — sort columns, dim_month,
--          fact_sales_monthly, and indexes
-- Run on:  Azure SQL (sql-retail-analytics-ks.database.windows.net)
-- Date:    April 1, 2026
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PART 1: Add missing sort columns to mart.dim_date
-- -----------------------------------------------------------------------------
alter table mart.dim_date add month_sort int null;
alter table mart.dim_date add quarter_sort int null;

update mart.dim_date
set month_sort = year_num * 100 + month_num;

update mart.dim_date
set quarter_sort = year_num * 100 + quarter_num;

-- -----------------------------------------------------------------------------
-- PART 2: Create mart.dim_month
-- -----------------------------------------------------------------------------
create table mart.dim_month (
    month_sort    int          not null,
    year_num      int          null,
    month_num     int          null,
    month_name    varchar(10)  null,
    month_abbr    varchar(3)   null,
    quarter_num   int          null,
    quarter_name  varchar(7)   null,
    quarter_sort  int          null,
    constraint pk_dim_month primary key (month_sort)
);

-- -----------------------------------------------------------------------------
-- PART 3: Create mart.fact_sales_monthly
-- -----------------------------------------------------------------------------
create table mart.fact_sales_monthly (
    id              int             not null,
    year_num        int             null,
    month_num       int             null,
    month_name      varchar(10)     null,
    month_abbr      varchar(3)      null,
    month_sort      int             null,
    quarter_num     int             null,
    quarter_name    varchar(7)      null,
    quarter_sort    int             null,
    store_key       int             null,
    product_key     int             null,
    total_sales     decimal(18,4)   null,
    total_sales_py  decimal(18,4)   null,
    total_qty       decimal(18,4)   null,
    total_qty_py    decimal(18,4)   null,
    date_created    datetime2       null,
    constraint pk_fact_sales_monthly primary key (id)
);

-- -----------------------------------------------------------------------------
-- PART 4: Indexes on mart.fact_sales_monthly
-- -----------------------------------------------------------------------------
create index ix_fsm_store_key     on mart.fact_sales_monthly (store_key);
create index ix_fsm_product_key   on mart.fact_sales_monthly (product_key);
create index ix_fsm_month_sort    on mart.fact_sales_monthly (month_sort);
create index ix_fsm_store_month   on mart.fact_sales_monthly (store_key, month_sort);
create index ix_fsm_product_month on mart.fact_sales_monthly (product_key, month_sort);

-- -----------------------------------------------------------------------------
-- PART 5: Verification
-- -----------------------------------------------------------------------------
select t.table_name, p.rows as row_count
from information_schema.tables t
join sys.partitions p
    on p.object_id = object_id(t.table_schema + '.' + t.table_name)
where t.table_schema = 'mart'
and t.table_type = 'BASE TABLE'
and p.index_id in (0,1)
order by t.table_name;