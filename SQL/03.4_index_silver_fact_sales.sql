-- ------------------------------------------------------------------------
-- Script:  03.4_index_silver_fact_sales.sql
-- Purpose: Add indexes to silver.fact_sales for query performance
-- ------------------------------------------------------------------------

-- primary filter by date
create index ix_fact_sales_sale_date
on silver.fact_sales (sale_date);

-- joins to product dimension
create index ix_fact_sales_upc
on silver.fact_sales (upc);

-- joins to store dimension
create index ix_fact_sales_store_nbr
on silver.fact_sales (store_nbr);

-- composite index for common query pattern - store + date
create index ix_fact_sales_store_date
on silver.fact_sales (store_nbr, sale_date);

-- composite index for common query pattern - product + date
create index ix_fact_sales_upc_date
on silver.fact_sales (upc, sale_date);