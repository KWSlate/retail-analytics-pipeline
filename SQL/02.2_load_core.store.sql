-- ------------------------------------------------------------------------
-- Script:  02.2_load_core.store.sql
-- Purpose: Load raw store dimension data from txt file
-- ------------------------------------------------------------------------
declare @File_to_load varchar(255) = 'C:\Users\kwsla\Documents\Retail_BI_Project\Raw Data\UK_Segmentation_FINAL_Store.txt'
declare @FileName varchar(100) = 'UK_Segmentation_FINAL_Store.txt'
declare @SQL nvarchar(500)

-- 1: Clear tables
truncate table core.store;

-- 2: Create temp load table
drop table if exists #store_load;
create table #store_load (
    store_nbr varchar(25),
    store_name varchar(200),
    city varchar(100),
    state varchar(100),
    zip_code varchar(10),
    store_type varchar(100),
    focus2 varchar(100),
    status varchar(50)
);

-- 3: Bulk load into temp table
set @SQL = N'bulk insert #store_load
from ''' + @File_to_load + '''
with (
    firstrow = 2,
    fieldterminator = ''\t'',
    rowterminator = ''0x0a'',
    tablock
);'

exec sp_executesql @SQL;

-- 4: Insert into core.store with audit columns
insert into core.store (
    store_nbr, store_name, city, state, zip_code,
    store_type, focus2, status, date_created, source_file_name
)
select
    store_nbr, store_name, city, state, zip_code,
    store_type, focus2, status,
    sysdatetime(),
    @FileName
from #store_load;