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
insert into stg.DV_Raw_Data_UK_2013 (
    DAY_DT, DAY_MAIN_DSC, RET_STORE_NBR_ID, WM_DEPT_TXT, WM_ACCT_DEPT_NBR_ID, 
    UPC_TXT, WJXBFS1, WJXBFS2, WJXBFS3, WJXBFS4, Date_Created, Source_File_Name
)
select
    trim(max(case when position = 1 then value end)),  -- DAY_DT
    trim(max(case when position = 2 then value end)),  -- DAY_MAIN_DSC
    trim(max(case when position = 3 then value end)),  -- RET_STORE_NBR_ID
    trim(max(case when position = 4 then value end)),  -- WM_DEPT_TXT
    trim(max(case when position = 5 then value end)),  -- WM_ACCT_DEPT_NBR_ID
    trim(max(case when position = 6 then value end)),  -- UPC_TXT
    trim(max(case when position = 7 then value end)),  -- WJXBFS1
    trim(max(case when position = 8 then value end)),  -- WJXBFS2
    trim(max(case when position = 9 then value end)),  -- WJXBFS3
    trim(max(case when position = 10 then value end)), -- WJXBFS4
    sysdatetime(),
    @FileName
from (
    select
        s.value,
        row_number() over (partition by l.RawLine order by (select null)) as position,
        l.RawLine
    from stg.DV_Raw_Data_UK_2013_Load l
    cross apply string_split(l.RawLine, '|') s
    where l.RawLine is not null
    and len(trim(l.RawLine)) > 0
) parsed
group by RawLine;