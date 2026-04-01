# Retail Analytics Pipeline & Dashboard

### End-to-End BI Portfolio Project — Ken Slate

---

## Overview

A complete end-to-end retail analytics solution demonstrating full-stack BI engineering capability — from raw data ingestion through dimensional modeling to executive-level Power BI reporting published in the cloud.

**112 million rows** of UK beverage retail POS data processed through a three-layer medallion architecture (Bronze → Silver → Mart), housed in Azure SQL, and surfaced through an interactive Power BI dashboard with dynamic dimension switching, geographic analysis, pricing analytics, and growth trend views.

> *Data used in this project is an anonymized historical retail dataset used for demonstration purposes only. Store names have been modified. No proprietary or confidential business information is represented.*

---

## Live Report

🔗 **[View Interactive Power BI Dashboard](https://app.powerbi.com/view?r=eyJrIjoiMDM5ODUyNjEtY2E3ZC00OTg4LWFjZmEtYjYzZTBlYzkwODI3IiwidCI6IjRmMTNhOWQwLWZhZWQtNDRhOS05NmEyLWEzYTk5OTA3OWY3MyJ9)**

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Database (local dev) | SQL Server 2022 Developer Edition |
| Database (cloud) | Azure SQL — Serverless free tier |
| ETL & Modeling | T-SQL (SSMS + VS Code) |
| Version Control | Git / GitHub Desktop |
| BI & Reporting | Power BI Desktop → Power BI Service |
| Cloud Migration | BCP (Bulk Copy Program) |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                       SOURCE DATA                           │
│          53 Daily POS Flat Files (pipe-delimited)           │
│               112M rows │ Apr 2024 – May 2025               │
└─────────────────────┬───────────────────────────────────────┘
                      │  Dynamic SQL bulk load
                      │  sp_executesql + STRING_SPLIT
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     BRONZE LAYER                            │
│               stg schema + core schema                      │
│    Single-column staging → parsed fact table                │
│    Raw product & store dimensions                           │
│    114,034,183 staged rows                                  │
└─────────────────────┬───────────────────────────────────────┘
                      │  Type casting, date shift +11 years
                      │  char(13) cleansing, deduplication
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                     SILVER LAYER                            │
│                   silver schema                             │
│    Normalized snowflake │ 14 dimension tables               │
│    Cleansed │ Typed │ Date-shifted │ Deduplicated           │
│    112,185,566 fact rows                                    │
└─────────────────────┬───────────────────────────────────────┘
                      │  Flatten snowflake → star schema
                      │  Surrogate keys, SCD Type 2
                      │  Monthly aggregation
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      MART LAYER                             │
│                    mart schema                              │
│    Star schema │ Surrogate keys │ SCD Type 2               │
│    fact_sales (112M daily) │ fact_sales_monthly (5.75M)    │
└─────────────────────┬───────────────────────────────────────┘
                      │  BCP export/import
                      │  ~3.25 hours at residential speed
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  AZURE SQL DATABASE                         │
│         sql-retail-analytics-ks.database.windows.net        │
│              Serverless free tier │ West US                 │
│              Mart layer only (dims + monthly fact)          │
└─────────────────────┬───────────────────────────────────────┘
                      │  Import mode │ 5.75M rows
                      │  Field Parameters │ DAX measures
                      ▼
┌─────────────────────────────────────────────────────────────┐
│               POWER BI SEMANTIC LAYER                       │
│    Star schema relationships │ Hierarchies                  │
│    30+ DAX measures │ 2 Field Parameters                    │
│    Conditional formatting │ Dynamic titles                  │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  POWER BI REPORT                            │
│    6 pages │ Executive Summary │ Geographic │ Top 10        │
│    Category & Brand │ Pricing │ Growth & Trends             │
│    Dynamic Focus selector │ Sales/Volume toggle             │
└─────────────────────────────────────────────────────────────┘
```

---

## Dataset

| Attribute | Detail |
|-----------|--------|
| Source | UK beverage retail POS system |
| Granularity | Daily — store × product |
| Date range | April 2024 – May 2025 (14 months, dates shifted +11 years from source) |
| Raw rows | 112,185,566 |
| Stores | 585 |
| Products | 1,888 unique UPCs |
| Categories | 8 |
| Subcategories | 25 |
| Brands | 291 |
| Suppliers | 76 |

---

## Key Engineering Decisions

**Why monthly aggregation?**
Source data is daily grain (112M rows). Power BI Import mode performs optimally under ~10M rows. Monthly aggregation at store × product level produces 5.75M rows — preserving full dimensional slicing capability while enabling fast interactive visuals. The daily grain fact table is retained in the mart for future DirectQuery or detailed analysis needs.

**Why SCD Type 2 on dimensions?**
Both `mart.dim_store` and `mart.dim_product` include `valid_from`, `valid_to`, `is_current`, and durable surrogate keys separate from natural keys. This supports point-in-time accuracy and enables tracking of attribute changes in a continuous pipeline scenario.

**Why a silver layer?**
For this single-source dataset, silver adds complexity that would not be strictly necessary in a bronze-to-mart design. Silver earns its place in production environments where multiple downstream marts share a single cleansed layer or where multiple heterogeneous source systems feed a common intermediate layer. It is included here to demonstrate full medallion architecture understanding.

**The 287 duplicate UPC problem:**
Three subcategories (Adult, Flavoured Water, Water) appeared under multiple parent categories in the source data due to a Seasonal promotional classification scheme. This caused 287 products to have duplicate rows in the mart dimension, inflating the fact table from 112M to 125M rows. Resolved using `ROW_NUMBER()` deduplication, preferring the non-Seasonal subcategory assignment. Full diagnostic scripts preserved in `04.3a_investigate_dim_product_duplicates.sql`.

**Why Field Parameters instead of duplicating visuals?**
The CMI tool (Ken's original Excel/VBA analytics platform) used macros to dynamically switch chart dimensions. Power BI's Field Parameters feature replicates this natively — one visual, one measure set, 12 selectable dimensions. The Focus By selector and Sales/Volume toggle together produce the same interactive experience as the original CMI tool without any custom code.

---

## Power BI Report Pages

| Page | Key Visuals | Interactive Features |
|------|-------------|---------------------|
| Executive Summary | 4 KPI cards, Monthly Sales vs PY combo chart, Top 20 products table | Sales/Volume toggle, cross-filtering |
| Geographic | UK bubble map (585 stores), Regional bar chart, Regional summary table with Sales/Store | Sales/Volume toggle |
| Top 10 | Dynamic Top N bar chart (CY/PY/YOY%), ranked product table | Focus By selector (12 dimensions), Sales/Volume toggle, Top N selector |
| Category & Brand | Category donut, Brand bar chart, Category metrics table | Sales/Volume toggle |
| Pricing | Sales & Avg Price combo, Avg Price by Category, Avg Price by Pack Size Type | Slicer filtering |
| Growth & Trends | CY vs PY trend lines, Sales vs PY by Category clustered bar | Sales/Volume toggle |

**Interactive features across the report:**
- **Focus By selector** — dynamically switches chart axis across 12 attributes (Category, Sub-Category, Supplier, Brand, Pack Size Type, Package, Product Description, Store Type, Region, State, City, Store Name)
- **Sales/Volume toggle** — switches all visuals between revenue (£) and unit metrics
- **Cross-filtering** — clicking any visual filters all others on the page
- **Conditional formatting** — YOY metrics display green (positive) or red (negative)
- **Dynamic titles** — chart titles update automatically with the Sales/Volume toggle

---

## Known Limitations & Future Iterations

**Assortment / Pareto Analysis:**
A Pareto chart (80/20 assortment efficiency analysis) was implemented in the original CMI tool using a custom Excel/VBA chart. The DAX measures for a Power BI Pareto implementation are fully written and included in `06.1_dax_measures.dax` (Cumulative Metric %, Pareto Band 80/95/100, Focus Item Rank). A Power BI Pareto visual is planned for a future iteration.

**Growth Forecast:**
Power BI's built-in forecast function requires a continuous date or numeric axis. This report uses a text-based month label axis (driven by the monthly grain model architecture and Import mode optimization) which is incompatible with the native forecast feature. A forecasting solution using DAX time intelligence or a custom Python/R visual against a daily date axis is planned for a future iteration.

---

## Pipeline Scripts

### Bronze Layer (`01.x` – `02.x`)

| Script | Description | Key Technique |
|--------|-------------|---------------|
| `01.1_create_stg_dv_raw_data_uk_2013.sql` | Staging fact table DDL | Single-column varchar staging |
| `01.2_create_stg_dv_raw_data_uk_2013_load.sql` | Load table DDL | — |
| `01.3_create_core_store.sql` | Store dimension DDL | — |
| `01.4_create_core_product.sql` | Product dimension DDL | — |
| `02.1_load_stg_dv_raw_data_uk.sql` | Bulk load 53 flat files | Dynamic SQL + sp_executesql |
| `02.2_load_core_store.sql` | Store dimension load | Quoted field CSV handling |
| `02.3_load_core_product.sql` | Product dimension load | — |
| `02.4_dimension_load_gap_check.sql` | Validation queries | 228 orphaned UPC exclusion |

### Silver Layer (`03.x`)

| Script | Description | Key Technique |
|--------|-------------|---------------|
| `03.1_load_silver_fact_sales.sql` | 112M row fact load | Date shift +11 years, INNER JOIN orphan exclusion |
| `03.2_load_silver_dim_store.sql` | Store snowflake dimensions | char(13) removal, new_store_flag derivation |
| `03.3_load_silver_dim_product.sql` | Product snowflake dimensions | pack_size_type derivation (Multipack/Large Single/Single Serve) |
| `03.4_index_silver_fact_sales.sql` | Performance indexes | 5 indexes on foreign keys and composites |
| `03.5_load_silver_dim_date.sql` | 426-row calendar dimension | Recursive CTE, OPTION (MAXRECURSION 500) |

### Mart Layer (`04.x`)

| Script | Description | Key Technique |
|--------|-------------|---------------|
| `04.0_create_mart_schema.sql` | Schema creation | — |
| `04.1_load_mart_dim_date.sql` | Date dimension | Quarter/month sort columns |
| `04.2_load_mart_dim_store.sql` | Flattened store dimension | SCD Type 2, durable keys |
| `04.3_load_mart_dim_product.sql` | Flattened product dimension | SCD Type 2, ROW_NUMBER() deduplication |
| `04.3a_investigate_dim_product_duplicates.sql` | Diagnostic queries | Multi-category subcategory investigation |
| `04.4_load_mart_fact_sales.sql` | 112M daily fact | Surrogate key resolution via joins |
| `04.5_index_mart_fact_sales.sql` | Performance indexes | Mirrors silver indexing strategy |
| `04.6_load_mart_fact_sales_monthly.sql` | 5.75M monthly aggregation | Import mode optimization |
| `04.7_add_sort_columns_dim_date.sql` | Sort columns | quarter_sort, month_sort for chronological ordering |

### Azure Migration (`05.x`)

| Script | Description | Key Technique |
|--------|-------------|---------------|
| `05.1_azure_create_mart_tables.sql` | DDL for Azure mart schema | — |
| `05.2_azure_migrate_data.bat` | BCP export/import commands | -b 10000 batch size, ~3.25hr for 112M rows |

### Power BI Documentation (`06.x`)

| File | Description |
|------|-------------|
| `06.1_dax_measures.dax` | All 30+ DAX measures with inline comments |

---

## How to Run

### Prerequisites
- SQL Server 2022 (Developer or Standard Edition)
- SSMS or Azure Data Studio
- Power BI Desktop (direct download version — not Microsoft Store)
- BCP utility (included with SQL Server installation)

### Steps
1. Clone this repository
2. Create database: `CREATE DATABASE Retail_Analytics`
3. Run scripts in order: `01.x` → `02.x` → `03.x` → `04.x`
4. Open `Retail_Analytics_Portfolio_01.pbix` in Power BI Desktop
5. Update data source connection to your SQL Server instance (`.\\SQLDEV` or your named instance)
6. Refresh data

> **Note:** Source flat files are not included in this repository due to size. Contact the repository owner for access.

> **Note:** Azure connection requires a Power BI Pro or Premium license to publish to Power BI Service. The free tier Azure SQL database resets monthly — verify row counts and indexes after each reset.

---

## About

**Ken Slate** — Senior Data Engineer / BI Analytics Engineer

30+ years of experience spanning data engineering, business intelligence, and category management analytics. Previously built the Category Management Insights (CMI) tool for Coca-Cola's Walmart International team — a sophisticated Excel/VBA analytics platform that contributed to a 5-year sales share CAGR of 2.5%. That tool is the direct inspiration for this project's Power BI report design.

This portfolio project demonstrates end-to-end capability from raw data pipeline through cloud-hosted executive reporting — the combination of pipeline engineering depth and business analytics domain knowledge that LinkedIn profile listings cannot convey.

📧 kwslate@bellsouth.net
💼 [LinkedIn](http://www.linkedin.com/in/kenslate)
📊 [Live Power BI Report](https://app.powerbi.com/view?r=eyJrIjoiMDM5ODUyNjEtY2E3ZC00OTg4LWFjZmEtYjYzZTBlYzkwODI3IiwidCI6IjRmMTNhOWQwLWZhZWQtNDRhOS05NmEyLWEzYTk5OTA3OWY3MyJ9)