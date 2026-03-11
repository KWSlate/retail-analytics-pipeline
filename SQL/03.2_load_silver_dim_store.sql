-- ------------------------------------------------------------------------
-- Script:  03.2_load_silver_dim_store.sql
-- Purpose: Create and populate silver store dimension tables
--          from core.store bronze data
--          Load sequence: dim_region → dim_store_type → dim_city → dim_store
-- ------------------------------------------------------------------------

-- drop existing tables in reverse dependency order (children first)
drop table if exists silver.dim_store;
drop table if exists silver.dim_city;
drop table if exists silver.dim_store_type;
drop table if exists silver.dim_region;


-- create dim_region
create table silver.dim_region (
    id   int identity(1,1) primary key,
    region  varchar(100),
    date_created datetime2(3)
);

-- create dim_store_type
create table silver.dim_store_type (
    id   int identity(1,1) primary key,
    store_type  varchar(100),
    date_created     datetime2(3)
);

-- create dim_city
create table silver.dim_city (
    id     int identity(1,1) primary key,
    city         varchar(100),
    state        varchar(100),
    zip_code     varchar(10),
    region_id   int,
    date_created datetime2(3)
);

-- create dim_store
create table silver.dim_store (
    id      int identity(1,1) primary key,
    store_nbr      varchar(25),
    store_name     varchar(200),
    new_store_flag  bit,
    city_id       int,
    store_type_id int,
    date_created   datetime2(3)
);

-- populate dim_region
insert into silver.dim_region (region, date_created)
select distinct
    focus2,
    sysdatetime()
from core.store
where focus2 is not null
order by focus2;

-- populate dim_store_type
insert into silver.dim_store_type (store_type, date_created)
select distinct
    store_type,
    sysdatetime()
from core.store
where store_type is not null
order by store_type;

-- populate dim_city

insert into silver.dim_city (city, state, zip_code, region_id, date_created)
select distinct
    store.city,
    store.state,
    store.zip_code,
    dim_region.id,
    sysdatetime()
from core.store store
inner join silver.dim_region dim_region on store.focus2 = dim_region.region;

-- populate dim_store
insert into silver.dim_store (store_nbr, store_name, new_store_flag, city_id, store_type_id, date_created)
select
    store.store_nbr,
    store.store_name,
    case when trim(replace(store.status, char(13), '')) = 'New' then 1 else 0 end as new_store_flag,
    dim_city.id,
    dim_store_type.id,
    sysdatetime()
from core.store store
inner join silver.dim_city dim_city on  store.city = dim_city.city
        and store.state = dim_city.state and store.zip_code = dim_city.zip_code
inner join silver.dim_store_type dim_store_type on store.store_type = dim_store_type.store_type;

-- verification counts
select 'dim_region'     as table_name, count(*) as row_count from silver.dim_region
union all
select 'dim_store_type' as table_name, count(*) as row_count from silver.dim_store_type
union all
select 'dim_city'       as table_name, count(*) as row_count from silver.dim_city
union all
select 'dim_store'      as table_name, count(*) as row_count from silver.dim_store;