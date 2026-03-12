-- ------------------------------------------------------------------------
-- Script:  04.2_create_and_load_mart_dim_store.sql
-- Purpose: Create and populate mart store dimension
--          Flattens silver snowflake: dim_store + dim_city + 
--          dim_region + dim_store_type into single denormalized table
-- ------------------------------------------------------------------------

-- drop and create mart.dim_store
drop table if exists mart.dim_store;
create table mart.dim_store (
    store_key      int identity(1,1) primary key,
    store_id       int,            -- durable key (stable across attribute changes)
    store_nbr      varchar(25),
    store_name     varchar(200),
    new_store_flag bit,
    store_type     varchar(100),
    city           varchar(100),
    state          varchar(100),
    zip_code       varchar(10),
    region         varchar(100),
    valid_from     date,           -- SCD Type 2: when this version became active
    valid_to       date,           -- SCD Type 2: when superseded (null = current)
    is_current     bit,            -- SCD Type 2: 1 = current record
    date_created   datetime2(3)
);

-- populate from silver - flatten snowflake into star
insert into mart.dim_store (store_id, store_nbr, store_name, new_store_flag, store_type, city, state, zip_code, region,
                            valid_from, valid_to, is_current, date_created)
select
    dim_store.id                as store_id,
    dim_store.store_nbr,
    dim_store.store_name,
    dim_store.new_store_flag,
    dim_store_type.store_type,
    dim_city.city,
    dim_city.state,
    dim_city.zip_code,
    dim_region.region      as region,
    -- SCD Type 2: all records current as of initial load
    cast('2024-04-27' as date)  as valid_from,
    null                        as valid_to,
    1                           as is_current,
    sysdatetime()
from silver.dim_store dim_store
    inner join silver.dim_city dim_city on dim_store.city_id = dim_city.id
    inner join silver.dim_region dim_region on dim_city.region_id = dim_region.id
    inner join silver.dim_store_type dim_store_type on dim_store.store_type_id = dim_store_type.id;

-- verification
select
    count(*)                                    as total_stores,
    sum(cast(is_current as int))                as current_records,
    count(distinct region)                      as regions,
    count(distinct store_type)                  as store_types,
    sum(cast(new_store_flag as int))            as new_stores
from mart.dim_store;