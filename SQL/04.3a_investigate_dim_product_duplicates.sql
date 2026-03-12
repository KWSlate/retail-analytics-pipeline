-- ------------------------------------------------------------------------
-- Script:  04.3a_investigate_dim_product_duplicates.sql
-- Purpose: Diagnostic queries used to identify and resolve duplicate UPCs
--          in mart.dim_product caused by Seasonal cross-category subcategory
--          assignments in source data.
-- Finding: silver.dim_product contains 2,175 rows but only 1,888 distinct
--          UPCs. 287 products are assigned to both a primary subcategory
--          AND a Seasonal subcategory under a different category.
-- Resolution: ROW_NUMBER() deduplication in 04.3, preferring non-Seasonal
--             subcategory. All 1,888 UPCs join cleanly to fact_sales.
-- ------------------------------------------------------------------------

-- check for duplicate UPCs in mart.dim_product
select 
    upc,
    count(*) as row_count
from mart.dim_product
where is_current = 1
group by upc
having count(*) > 1
order by count(*) desc;

-- how many products are duplicated
select 
    count(*) as duplicate_upc_count
from (
    select upc
    from mart.dim_product
    where is_current = 1
    group by upc
    having count(*) > 1
) dupes;

-- confirm these are the multi-category subcategory products
select 
    dim_product.upc,
    dim_product.subcategory,
    dim_product.category,
    count(*) as row_count
from mart.dim_product
where is_current = 1
group by dim_product.upc, dim_product.subcategory, dim_product.category
having count(*) > 1
order by dim_product.subcategory;

-- check which category each duplicate subcategory should belong to
select 
    dim_subcategory.subcategory,
    dim_category.category,
    count(*) as product_count
from silver.dim_product dim_product
inner join silver.dim_subcategory dim_subcategory 
    on dim_product.subcategory_id = dim_subcategory.id
inner join silver.dim_category dim_category 
    on dim_subcategory.category_id = dim_category.id
where dim_subcategory.subcategory in ('Adult', 'Flavoured Water', 'Water')
group by dim_subcategory.subcategory, dim_category.category
order by dim_subcategory.subcategory, count(*) desc;

-- check if same UPC appears under different subcategory_ids in silver
select 
    dim_product.upc,
    dim_product.description,
    dim_subcategory.subcategory,
    dim_category.category
from silver.dim_product dim_product
inner join silver.dim_subcategory dim_subcategory 
    on dim_product.subcategory_id = dim_subcategory.id
inner join silver.dim_category dim_category 
    on dim_subcategory.category_id = dim_category.id
where dim_subcategory.subcategory in ('Adult', 'Flavoured Water', 'Water')
order by dim_product.upc, dim_subcategory.subcategory;

-- check core.product for these subcategories
select 
    upc,
    description,
    category,
    subcategory
from core.product
where subcategory in ('Adult', 'Flavoured Water', 'Water')
order by subcategory, category, upc;

