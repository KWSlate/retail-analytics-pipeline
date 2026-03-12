-- ------------------------------------------------------------------------
-- Script:  04.3b_reload_mart_product.sql
-- Purpose: fix product table causing duplicates in mart.fact_sales table
-- ------------------------------------------------------------------------

-- rebuild mart.dim_product with deduplication
drop table if exists mart.dim_product;
create table mart.dim_product (
    product_key    int identity(1,1) primary key,
    product_id     int,
    upc            varchar(50),
    description    varchar(100),
    dept_nbr       int,
    prime_item_nbr varchar(50),
    brand          varchar(100),
    supplier       varchar(100),
    category       varchar(100),
    subcategory    varchar(100),
    package        varchar(100),
    pack_size_type varchar(20),
    valid_from     date,
    valid_to       date,
    is_current     bit,
    date_created   datetime2(3)
);

insert into mart.dim_product (product_id, upc, description, dept_nbr, prime_item_nbr, brand, supplier, category, subcategory,
                                package, pack_size_type, valid_from, valid_to, is_current, date_created)
select
    product_id, upc, description, dept_nbr, prime_item_nbr, brand, supplier, category, subcategory,
                package, pack_size_type, valid_from, valid_to, is_current, date_created
from (
    select
        dim_product.id              as product_id,
        dim_product.upc,
        dim_product.description,
        dim_product.dept_nbr,
        dim_product.prime_item_nbr,
        dim_brand.brand,
        dim_supplier.supplier,
        dim_category.category,
        dim_subcategory.subcategory,
        dim_package.package,
        dim_package.pack_size_type,
        cast('2024-04-27' as date)  as valid_from,
        null                        as valid_to,
        1                           as is_current,
        sysdatetime()               as date_created,
        -- rank rows per UPC: prefer non-Seasonal subcategory
        row_number() over (
            partition by dim_product.upc
            order by
                case when dim_subcategory.subcategory = 'Seasonal' 
                     then 1 else 0 end asc,  -- non-Seasonal wins
                dim_category.category asc     -- tiebreaker: alphabetical
        ) as rn
    from silver.dim_product dim_product 
        inner join silver.dim_brand dim_brand on dim_product.brand_id = dim_brand.id
        inner join silver.dim_supplier dim_supplier on dim_product.supplier_id = dim_supplier.id
        inner join silver.dim_subcategory dim_subcategory on dim_product.subcategory_id = dim_subcategory.id
        inner join silver.dim_category dim_category on dim_subcategory.category_id = dim_category.id
        inner join silver.dim_package dim_package on dim_product.package_id = dim_package.id
) ranked
where rn = 1;

-- verification
select
    count(*)                            as total_products,
    sum(cast(is_current as int))        as current_records,
    count(distinct upc)                 as distinct_upcs,
    count(distinct brand)               as brands,
    count(distinct category)            as categories,
    count(distinct subcategory)         as subcategories
from mart.dim_product;