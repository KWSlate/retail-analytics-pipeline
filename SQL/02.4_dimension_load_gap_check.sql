-- ------------------------------------------------------------------------
-- Script:  02.4_dimension_load_gap_check.sql
-- Purpose: Referential integrity check between fact and dimension data
-- ------------------------------------------------------------------------
-- UPCs in fact that are missing from product
select distinct upc_txt
from stg.dv_raw_data_uk_2013
where upc_txt not in (select upc from core.product);

-- Store numbers in fact that are missing from store
select distinct ret_store_nbr_id
from stg.dv_raw_data_uk_2013
where ret_store_nbr_id not in (select store_nbr from core.store);