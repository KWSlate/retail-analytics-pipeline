-- ------------------------------------------------------------------------
-- Script:  02.3_load_core_product.sql
-- Purpose: Load raw product dimension data from CSV file
-- ------------------------------------------------------------------------
declare @File_to_load varchar(255) = 'C:\Users\kwsla\Documents\Retail_BI_Project\Raw Data\UK_Segmentation_FINAL_Item.csv'
declare @FileName varchar(100) = 'UK_Segmentation_FINAL_Item.csv'
declare @SQL nvarchar(500)

-- 1: Clear tables
truncate table core.product;

-- 2: Create temp load table
drop table if exists #product_load;
create table #product_load (
    upc varchar(50),
    dept_nbr varchar(10),
    prime_item_nbr varchar(50),
    description varchar(100),
    supplier varchar(100),
    category varchar(100),
    subcategory varchar(100),
    brand varchar(100),
    package varchar(100)
);

-- 3: Bulk load into temp table
set @SQL = N'bulk insert #product_load
from ''' + @File_to_load + '''
with (
    firstrow = 2,
    fieldterminator = '','',
    rowterminator = ''0x0a'',
    tablock
);'

exec sp_executesql @SQL;

-- 4: Insert into core.product with audit columns
insert into core.product (
    upc, dept_nbr, prime_item_nbr, description, supplier,
    category, subcategory, brand, package,
    date_created, source_file_name
)
select
    upc, cast(dept_nbr as int), prime_item_nbr, description, supplier,
    category, subcategory, brand, package,
    sysdatetime(),
    @FileName
from #product_load;