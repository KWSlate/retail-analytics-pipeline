-- ------------------------------------------------------------------------
-- Script:  04.5_index_mart_fact_sales.sql
-- Purpose: Add indexes to mart.fact_sales to support Power BI query patterns
--          Mirrors silver layer indexing strategy with mart surrogate keys
-- ------------------------------------------------------------------------

-- date_key: supports time-based filtering and trending (most common filter)
create nonclustered index ix_mart_fact_sales_date_key
    on mart.fact_sales (date_key);

-- store_key: supports store and region filtering
create nonclustered index ix_mart_fact_sales_store_key
    on mart.fact_sales (store_key);

-- product_key: supports product, brand, category filtering
create nonclustered index ix_mart_fact_sales_product_key
    on mart.fact_sales (product_key);

-- store + date composite: supports store performance over time
create nonclustered index ix_mart_fact_sales_store_date
    on mart.fact_sales (store_key, date_key);

-- product + date composite: supports product trending over time
create nonclustered index ix_mart_fact_sales_product_date
    on mart.fact_sales (product_key, date_key);

-- ------------------------------------------------------------------------
-- verification: confirm all indexes created successfully
-- ------------------------------------------------------------------------
select
    i.name          as index_name,
    i.type_desc     as index_type,
    c.name          as column_name,
    ic.key_ordinal  as key_position
from sys.indexes i
inner join sys.index_columns ic
    on i.object_id = ic.object_id
    and i.index_id = ic.index_id
inner join sys.columns c
    on ic.object_id = c.object_id
    and ic.column_id = c.column_id
where i.object_id = object_id('mart.fact_sales')
    and i.type_desc = 'NONCLUSTERED'
order by i.name, ic.key_ordinal;