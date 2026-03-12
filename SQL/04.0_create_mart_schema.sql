-- ------------------------------------------------------------------------
-- Script: 04.0_create_mart_schema.sql
-- ------------------------------------------------------------------------

if not exists (select 1 from sys.schemas where name = 'mart')
    exec('create schema mart');