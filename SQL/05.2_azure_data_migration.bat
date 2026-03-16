-- ------------------------------------------------------------------------
-- Script:  05.2_azure_data_migration.bat
-- Purpose: BCP commands to migrate mart layer from local SQL Server
--          to Azure SQL Database, run from Windows Command Prompt
--          Local server:  .\SQLDEV (Windows auth)
--          Azure server:  sql-retail-analytics-ks.database.windows.net
--          Azure login:   azuresserver
-- ------------------------------------------------------------------------

-- ------------------------------------------------------------------------
-- EXPORT from local SQL Server to bcp files in C:\Temp
-- ------------------------------------------------------------------------

-- dim_date (426 rows)
bcp Retail_Analytics.mart.dim_date out "C:\Temp\dim_date.bcp" -S .\SQLDEV -T -n

-- dim_store (585 rows)
bcp Retail_Analytics.mart.dim_store out "C:\Temp\dim_store.bcp" -S .\SQLDEV -T -n

-- dim_product (1,888 rows)
bcp Retail_Analytics.mart.dim_product out "C:\Temp\dim_product.bcp" -S .\SQLDEV -T -n

-- fact_sales (112,185,566 rows)
bcp Retail_Analytics.mart.fact_sales out "C:\Temp\fact_sales.bcp" -S .\SQLDEV -T -n

-- ------------------------------------------------------------------------
-- IMPORT from bcp files to Azure SQL Database
-- ------------------------------------------------------------------------

-- dim_date
bcp Retail_Analytics.mart.dim_date in "C:\Temp\dim_date.bcp" -S sql-retail-analytics-ks.database.windows.net -U azuresserver -P <password> -n

-- dim_store
bcp Retail_Analytics.mart.dim_store in "C:\Temp\dim_store.bcp" -S sql-retail-analytics-ks.database.windows.net -U azuresserver -P <password> -n

-- dim_product
bcp Retail_Analytics.mart.dim_product in "C:\Temp\dim_product.bcp" -S sql-retail-analytics-ks.database.windows.net -U azuresserver -P <password> -n

-- fact_sales (-b 10000 sets batch size for large load progress visibility)
bcp Retail_Analytics.mart.fact_sales in "C:\Temp\fact_sales.bcp" -S sql-retail-analytics-ks.database.windows.net -U azuresserver -P <password> -n -b 10000

-- ------------------------------------------------------------------------
-- Confirmed row counts after migration:
-- dim_date:    426 rows
-- dim_store:   585 rows
-- dim_product: 1,888 rows
-- fact_sales:  112,185,566 rows
-- ------------------------------------------------------------------------
