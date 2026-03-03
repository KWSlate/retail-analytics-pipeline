declare @File_to_load varchar(255) = 'C:\Users\kwsla\Documents\Retail_BI_Project\Raw Data\Data Ventures UK 2014.06.01\DV Raw Data - UK 2014\DV Raw Data - UK 2014.01.txt'
declare @FileName varchar(100) = 'DV Raw Data - UK 2014.01.txt'
declare @SQL nvarchar(500)

-- 1: Clear load table before each file
truncate table stg.DV_Raw_Data_UK_2013_Load;

-- 2: Build dynamic SQL to allow variable in BULK INSERT path
set @SQL = N'bulk insert stg.DV_Raw_Data_UK_2013_Load
from ''' + @File_to_load + '''
with (
    firstrow = 2,
    rowterminator = ''0x0a'',
    tablock
);'

exec sp_executesql @SQL;

-- 3: Parse and insert into DV_Raw_Data_UK_2013, trimming whitespace
insert into stg.DV_Raw_Data_UK_2013 (DAY_DT, DAY_MAIN_DSC, RET_STORE_NBR_ID, WM_DEPT_TXT, WM_ACCT_DEPT_NBR_ID, UPC_TXT,
                                     WJXBFS1, WJXBFS2, WJXBFS3, WJXBFS4, Date_Created, Source_File_Name)
select
    trim(parsename(replace(RawLine,'|','.'),10)), -- DAY_DT
    trim(parsename(replace(RawLine,'|','.'),9)),  -- DAY_MAIN_DSC
    trim(parsename(replace(RawLine,'|','.'),8)),  -- RET_STORE_NBR_ID
    trim(parsename(replace(RawLine,'|','.'),7)),  -- WM_DEPT_TXT
    trim(parsename(replace(RawLine,'|','.'),6)),  -- WM_ACCT_DEPT_NBR_ID
    trim(parsename(replace(RawLine,'|','.'),5)),  -- UPC_TXT
    trim(parsename(replace(RawLine,'|','.'),4)),  -- WJXBFS1
    trim(parsename(replace(RawLine,'|','.'),3)),  -- WJXBFS2
    trim(parsename(replace(RawLine,'|','.'),2)),  -- WJXBFS3
    trim(parsename(replace(RawLine,'|','.'),1)),  -- WJXBFS4
    sysdatetime(),
    @FileName
from stg.DV_Raw_Data_UK_2013_Load
where RawLine is not null 
and len(trim(RawLine)) > 0;  -- Skip blank rows including trailing blank line