-- ------------------------------------------------------------------------
-- Script:  03.3_load_silver_dim_product.sql
-- Purpose: Create and populate silver product dimension tables
--          from core.product bronze data
--          Load sequence: dim_supplier → dim_brand → dim_category → 
--                         dim_subcategory → dim_product
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- Data Governance
-- note: subcategory 'Adult' appears under both 'Adult' and 'Seasonal' categories
-- 3 products (Appletiser x2, Lipton Iced Tea) categorized as Adult/Adult
-- retained as-is from source data - categorization unverified but plausible
-- also: 'Flavoured Water' and 'Water' subcategories appear under multiple categories
-- this reflects legitimate product hierarchy overlap in source data
-- ------------------------------------------------------------------------

-- drop existing tables in reverse dependency order (children first)
drop table if exists silver.dim_product;
drop table if exists silver.dim_subcategory;
drop table if exists silver.dim_category;
drop table if exists silver.dim_brand;
drop table if exists silver.dim_supplier;
drop table if exists silver.dim_package;

-- create dim_supplier
create table silver.dim_supplier (
    id           int identity(1,1) primary key,
    supplier     varchar(100),
    date_created datetime2(3)
);

-- create dim_brand
create table silver.dim_brand (
    id           int identity(1,1) primary key,
    brand        varchar(100),
    date_created datetime2(3)
);

-- create dim_category
create table silver.dim_category (
    id           int identity(1,1) primary key,
    category     varchar(100),
    date_created datetime2(3)
);

-- create dim_subcategory
create table silver.dim_subcategory (
    id           int identity(1,1) primary key,
    subcategory  varchar(100),
    category_id  int,
    date_created datetime2(3)
);

-- create dim_package
create table silver.dim_package (
    id             int identity(1,1) primary key,
    package        varchar(100),
    pack_size_type varchar(20),
    date_created   datetime2(3)
);

-- create dim_product
create table silver.dim_product (
    id             int identity(1,1) primary key,
    upc            varchar(50),
    dept_nbr       int,
    prime_item_nbr varchar(50),
    description    varchar(100),
    brand_id       int,
    supplier_id    int,
    subcategory_id int,
    package_id     int,
    date_created   datetime2(3)
);

-- populate dim_supplier
insert into silver.dim_supplier (supplier, date_created)
select distinct
    supplier,
    sysdatetime()
from core.product
where supplier is not null
order by supplier;

-- populate dim_brand
insert into silver.dim_brand (brand, date_created)
select distinct
    brand,
    sysdatetime()
from core.product
where brand is not null
order by brand;

-- populate dim_category
insert into silver.dim_category (category, date_created)
select distinct
    category,
    sysdatetime()
from core.product
where category is not null
order by category;

-- populate dim_subcategory
insert into silver.dim_subcategory (subcategory, category_id, date_created)
select distinct
    product.subcategory,
    dim_category.id,
    sysdatetime()
from core.product product
inner join silver.dim_category dim_category 
    on product.category = dim_category.category
where product.subcategory is not null;

-- populate dim_package
insert into silver.dim_package (package, pack_size_type, date_created)
select distinct
    product.package,
    case
        when product.package like '%pk%' then 'Multipack'
        when product.package like '%lt%'
             and try_cast(
                 left(trim(product.package),
                 charindex(' ', trim(product.package)) - 1)
                 as decimal(5,2)) >= 1.5  then 'Large Single'
        else 'Single Serve'
    end as pack_size_type,
    sysdatetime()
from core.product product
where product.package is not null
order by product.package;

-- populate dim_product
insert into silver.dim_product (upc, dept_nbr, prime_item_nbr, description, brand_id,
                                supplier_id, subcategory_id, package_id, date_created)
select
    product.upc,
    product.dept_nbr,
    product.prime_item_nbr,
    product.description,
    dim_brand.id,
    dim_supplier.id,
    dim_subcategory.id,
    dim_package.id,
    sysdatetime()
from core.product product
inner join silver.dim_brand dim_brand on product.brand = dim_brand.brand
inner join silver.dim_supplier dim_supplier on product.supplier = dim_supplier.supplier
inner join silver.dim_subcategory dim_subcategory on product.subcategory = dim_subcategory.subcategory
inner join silver.dim_package dim_package on product.package = dim_package.package;

-- verification counts
select 'dim_supplier'    as table_name, count(*) as row_count from silver.dim_supplier
union all
select 'dim_brand'       as table_name, count(*) as row_count from silver.dim_brand
union all
select 'dim_category'    as table_name, count(*) as row_count from silver.dim_category
union all
select 'dim_subcategory' as table_name, count(*) as row_count from silver.dim_subcategory
union all
select 'dim_package'     as table_name, count(*) as row_count from silver.dim_package
union all
select 'dim_product'     as table_name, count(*) as row_count from silver.dim_product;