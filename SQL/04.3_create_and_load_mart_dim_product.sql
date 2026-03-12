-- ------------------------------------------------------------------------
-- Script:  04.3_create_and_load_mart_dim_product.sql
-- Purpose: Create and populate mart product dimension
--          Flattens silver snowflake: dim_product + dim_brand + 
--          dim_supplier + dim_category + dim_subcategory + dim_package
--          into single denormalized table
-- ------------------------------------------------------------------------

-- drop and create mart.dim_product
drop table if exists mart.dim_product;
create table mart.dim_product (
    product_key    int identity(1,1) primary key,
    product_id     int,            -- durable key (stable across UPC changes)
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
    valid_from     date,           -- SCD Type 2: when this version became active
    valid_to       date,           -- SCD Type 2: when superseded (null = current)
    is_current     bit,            -- SCD Type 2: 1 = current record
    date_created   datetime2(3)
);

-- populate from silver - flatten snowflake into star
insert into mart.dim_product (product_id, upc, description, dept_nbr, prime_item_nbr, brand, supplier, category, subcategory,
                                package, pack_size_type, valid_from, valid_to, is_current, date_created)
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
    -- SCD Type 2: all records current as of initial load
    cast('2024-04-27' as date)  as valid_from,
    null                        as valid_to,
    1                           as is_current,
    sysdatetime()
from silver.dim_product dim_product
    inner join silver.dim_brand dim_brand on dim_product.brand_id = dim_brand.id
    inner join silver.dim_supplier dim_supplier on dim_product.supplier_id = dim_supplier.id
    inner join silver.dim_subcategory dim_subcategory on dim_product.subcategory_id = dim_subcategory.id
    inner join silver.dim_category dim_category on dim_subcategory.category_id = dim_category.id
    inner join silver.dim_package dim_package on dim_product.package_id = dim_package.id;

-- verification
select
    count(*)                            as total_products,
    sum(cast(is_current as int))        as current_records,
    count(distinct brand)               as brands,
    count(distinct supplier)            as suppliers,
    count(distinct category)            as categories,
    count(distinct subcategory)         as subcategories,
    count(distinct pack_size_type)      as pack_size_types
from mart.dim_product;