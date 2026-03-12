-- ------------------------------------------------------------------------
-- Script:  04.4_create_and_load_mart_fact_sales.sql
-- Purpose: Create and populate mart fact table
--          Replaces natural keys with surrogate keys from mart dimensions
-- ------------------------------------------------------------------------

-- drop and create mart.fact_sales
drop table if exists mart.fact_sales;
create table mart.fact_sales (
    fact_id      int identity(1,1) primary key,
    date_key     int,            -- FK to mart.dim_date
    store_key    int,            -- FK to mart.dim_store
    product_key  int,            -- FK to mart.dim_product
    sales        decimal(18,4),
    sales_py     decimal(18,4),
    qty          decimal(18,4),
    qty_py       decimal(18,4),
    date_created datetime2(3)
);

-- populate from silver.fact_sales. Replace natural keys with surrogate keys via joins to mart dims
insert into mart.fact_sales (date_key, store_key, product_key, sales, sales_py, qty, qty_py, date_created)
select
    dim_date.date_key,
    dim_store.store_key,
    dim_product.product_key,
    fact.sales,
    fact.sales_py,
    fact.qty,
    fact.qty_py,
    sysdatetime()
from silver.fact_sales fact
    inner join mart.dim_date dim_date on fact.sale_date = dim_date.date
    inner join mart.dim_store dim_store on fact.store_nbr = dim_store.store_nbr and dim_store.is_current = 1
    inner join mart.dim_product dim_product on fact.upc = dim_product.upc and dim_product.is_current = 1;

-- verification
select
    count(*)                as total_rows,
    min(dim_date.date)      as first_sale_date,
    max(dim_date.date)      as last_sale_date,
    count(distinct fact.store_key)   as stores,
    count(distinct fact.product_key) as products
from mart.fact_sales fact
inner join mart.dim_date dim_date on fact.date_key = dim_date.date_key;