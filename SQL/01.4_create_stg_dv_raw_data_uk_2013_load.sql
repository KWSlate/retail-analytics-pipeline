-- create a temporary single-column staging table for loading raw fixed-width pipe-delimited data
create table stg.DV_Raw_Data_UK_2013_Load (
    RawLine varchar(2000));