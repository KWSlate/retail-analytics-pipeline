Retail Analytics Portfolio — Project Playbook
A Technical Narrative of Design Decisions, Challenges & Solutions
Author: Ken Slate
Project Duration: January 2026 – Present
GitHub: https://github.com/kwslate/retail-analytics-pipeline

Executive Summary
This project is an end-to-end retail analytics pipeline built as a career portfolio artifact. It processes 112 million rows of UK beverage retail POS data through a three-layer medallion architecture, culminating in an interactive Power BI executive dashboard hosted in Azure SQL and published to Power BI Service.
The project was motivated by a career transition following a layoff on December 31, 2025. The goal was to demonstrate full-stack BI engineering capability — from raw file ingestion through dimensional modeling to published interactive reporting — in a single cohesive portfolio piece.
What distinguishes this project from typical portfolio work is the combination of genuine engineering scale (112M rows, 53 source files, cloud migration) with business-domain sophistication (category management analytics, SCD Type 2, Field Parameters, dynamic measure switching). The technical decisions throughout reflect real-world production patterns, not textbook exercises.

Background & Motivation
The Business Context
Ken Slate brings 30+ years of experience spanning data engineering and category management analytics. Before transitioning to pure data engineering, he built the Category Management Insights (CMI) tool — a sophisticated Excel/VBA analytics platform used by Coca-Cola's Walmart International team that contributed to a 5-year sales share CAGR of 2.5%.
That CMI tool is the direct inspiration for this portfolio project's Power BI report design. The goal was to recreate and surpass those analytical capabilities using modern BI tooling, while building the full data pipeline behind it — something the original CMI tool lacked.
Why This Dataset
The source data is UK beverage retail POS data — daily sales at store × product grain covering 53 weeks. Originally from 2013-2014, dates were shifted forward 11 years to appear near-current (2024-2025). Store names were anonymized. The dataset was chosen because it is large enough to demonstrate real engineering challenges (bulk loading, performance indexing, cloud migration) while being rich enough to support genuine business analytics (category share, pricing, growth trends, geographic performance).

Disclaimer: Data is an anonymized historical retail dataset used for demonstration purposes only. No proprietary or confidential business information is represented.

The Career Goal
Targeting BI Engineer and Analytics Engineer contracting roles. Remote work preferred. The portfolio project is designed to demonstrate capabilities that LinkedIn profile listings cannot — specifically the combination of pipeline engineering depth with business analytics sophistication.

Chapter 1: Infrastructure Setup
Tool Selection
SQL Server 2022 Developer Edition was chosen over SQL Server Express after quickly hitting Express's 10GB database size limit during initial data loading. The Developer Edition is free, full-featured, and appropriate for development and portfolio work.
Key decision: Named instance .\SQLDEV rather than the default instance, preserving the ability to run other SQL Server instances side by side.
Environment

Local development machine: Lenovo ThinkPad X1, Windows 11
SQL Server Management Studio (SSMS) + VS Code for SQL development
GitHub Desktop for version control
Power BI Desktop (direct download, not Microsoft Store version — Store version caused persistent authentication popup issues)

Version Control Strategy
All SQL scripts committed to GitHub with descriptive commit messages designed to serve as project documentation. Script naming convention: [phase].[sequence]_[action]_[object].sql. This numbering scheme allows scripts to be run in order from a clean database with no ambiguity.

Chapter 2: Bronze Layer
Source Data Characteristics
53 pipe-delimited flat files with fixed-width padding, UTF-8 encoding, LF line endings. Each file represents one week of data across all stores and products. Four measure columns per row: Sales, Sales PY (prior year), Qty, Qty PY.
Columns: DAY_DT, DAY_MAIN_DSC, STORE_NBR, ACCT_DEPT_NBR, UPC, WJXBFS1 (Sales), WJXBFS2 (Sales PY), WJXBFS3 (Qty), WJXBFS4 (Qty PY)
The Bulk Load Challenge
The natural approach — BULK INSERT with a variable file path — doesn't work in SQL Server. BULK INSERT requires a literal string path, not a variable.
Solution: Dynamic SQL using sp_executesql to construct and execute the BULK INSERT statement with a variable path, looping through all 53 files programmatically.
A second challenge was parsing the pipe-delimited fixed-width format. PARSENAME() is limited to 4 parts.
Solution: Single-column staging table — load each entire row as one varchar column, then use STRING_SPLIT() to parse into individual columns. This pattern handles any number of columns regardless of delimiter complexity.
Data Quality — 228 Orphaned UPCs
Cross-referencing the fact data against the product dimension revealed 228 UPCs in the fact table with no matching product record. These were excluded via INNER JOIN rather than LEFT JOIN in all downstream loads. This was a deliberate scope decision — the orphaned UPCs were artifacts of the original study design and not meaningful for analysis.
Bronze Architecture
stg.dv_raw_data_uk_2013_load  (single-column transient staging)
         ↓ STRING_SPLIT parsing
stg.dv_raw_data_uk_2013        (114,034,183 rows — fully typed)
core.store                     (store dimension — raw)
core.product                   (product dimension — raw)

Chapter 3: Silver Layer
Design Philosophy
The silver layer normalizes the raw bronze data into a clean snowflake schema — typed, cleansed, and structured for analysis. Fact data is loaded with a date shift (+11 years) to bring 2013-2014 dates into a near-current 2024-2025 window.
The char(13) Problem
The store dimension's status field contained carriage returns (char(13)) embedded in string values. A store with status "New" was actually stored as "New\r" — making string comparisons fail silently.
Solution: trim(replace(store.status, char(13), '')) applied during silver load. This produced the new_store_flag bit column cleanly.
Silver Store Snowflake
silver.dim_region (7 rows)
silver.dim_store_type (10 rows)
silver.dim_city → silver.dim_region
silver.dim_store → silver.dim_city + silver.dim_store_type
Silver Product Snowflake
silver.dim_category (8 rows)
silver.dim_subcategory (25 rows) → silver.dim_category
silver.dim_brand (291 rows)
silver.dim_supplier (76 rows)
silver.dim_package (119 rows, includes pack_size_type derivation)
silver.dim_product (2,175 rows) → all of the above
pack_size_type derivation: 'Multipack' (description contains 'pk'), 'Large Single' (≥1.5 liters), 'Single Serve' (everything else).
The Multi-Category Subcategory Issue
Three subcategory names — Adult, Flavoured Water, Water — appeared under multiple parent categories in the source data. This was a legitimate business classification: these subcategories were used as both primary product descriptors AND seasonal promotional tags.
Impact in silver: 25 subcategory rows (22 distinct names). Documented as a known business rule.
Impact in mart: This caused 287 products to appear twice in mart.dim_product when flattening the snowflake, inflating fact_sales from 112M to 125M rows.
Silver Calendar
silver.dim_date covers 2024-04-01 through 2025-05-31 (426 days). Week starts Sunday. Generated via recursive CTE with OPTION (MAXRECURSION 500) — the default 100 is insufficient for 426 iterations.

Chapter 4: Mart Layer (Star Schema)
Design Goals
The mart layer is optimized for Power BI consumption:

Surrogate keys replace natural keys
Snowflake dimensions flattened into single wide tables
SCD Type 2 columns on dimensions
Monthly aggregation for Power BI Import mode performance

SCD Type 2 Implementation
Both mart.dim_store and mart.dim_product include:

valid_from date — when this version of the record became active
valid_to date — when superseded (NULL = current)
is_current bit — current record indicator
Durable key (store_id, product_id) — stable across attribute changes
Surrogate key (store_key, product_key) — changes with each new version

For the initial load, all records are current (is_current = 1, valid_from = 2024-04-27, valid_to = NULL). This architecture supports future incremental loads with change tracking.
The Duplicate UPC Problem
When loading mart.dim_product, the row count came back as 2,175 instead of the expected 1,888 unique UPCs. The 287 extra rows were caused by the multi-category subcategory issue: products assigned to the "Seasonal" subcategory appeared under both their primary category AND the Seasonal category.
Diagnostic process: Queried for UPCs with row_count > 1, confirmed all 287 duplicates were from Adult, Flavoured Water, or Water subcategories appearing under Seasonal.
Solution: ROW_NUMBER() OVER (PARTITION BY upc ORDER BY CASE WHEN subcategory = 'Seasonal' THEN 1 ELSE 0 END) — selects the non-Seasonal row for each duplicate UPC. Full diagnostic scripts preserved in 04.3a_investigate_dim_product_duplicates.sql.
Result: 1,888 rows, 1,888 distinct UPCs, 0 unmatched rows in fact_sales.
Monthly Aggregation Decision
The daily grain fact table (112M rows) was retained in the mart but a monthly aggregation table was created as the primary Power BI source:
GrainRowsUse CaseDaily × Store × Product112,185,566Full detail, retained for future useMonthly × Store × Product5,022,794Power BI Import mode
The monthly aggregation preserves full store and product dimension keys, enabling all slicers and cross-filtering. The design decision is documented in the script header.
mart.dim_month
A dedicated month dimension table was created to serve as the Power BI axis table for time-based visuals. 14 rows covering April 2024 through May 2025 (the full dataset range including partial boundary months). Contains month_sort and quarter_sort integer columns for correct chronological ordering in Power BI visuals.
Indexes
Five indexes on mart.fact_sales_monthly: individual indexes on store_key, product_key, and month_sort, plus composite indexes on store_key + month_sort and product_key + month_sort. Mirrors the silver indexing strategy.

Chapter 5: Azure Migration
Why Azure
A cloud database connection is required for publishing live Power BI reports to Power BI Service. Azure SQL also demonstrates cloud data engineering capability for the portfolio.
Setup

Resource group: rg-retail-analytics
Server: sql-retail-analytics-ks (West US — East US had capacity restrictions for new accounts)
Database: Retail_Analytics — free tier (100,000 vCore seconds, 32GB storage, lifetime of subscription)
Authentication: SQL authentication, login azuresserver
Firewall: client IP whitelisted

Migration Approach
BCP (Bulk Copy Program) utility — export from local SQL Server, import to Azure. Chosen over SSMS Import/Export Wizard for reliability with large datasets and better progress visibility (-b 10000 batch size parameter).
April 1, 2026 — Azure Free Tier Reset & Completion
After the free tier reset, the following tasks were completed to finalize the Azure mart layer:

Added month_sort and quarter_sort columns to mart.dim_date — these were added to the local dev instance after the original migration and were missing from Azure.
Created and loaded mart.dim_month (14 rows) — this table was added to the local model after the original migration.
Created and loaded mart.fact_sales_monthly (5,022,794 rows) — the monthly aggregation table was built after the original migration.
Added 5 performance indexes to mart.fact_sales_monthly.
Re-pointed Power BI Desktop from local .\SQLDEV to Azure SQL.
Confirmed all 6 report pages render correctly from Azure data.

Performance:
TableRowsExport TimeImport Timedim_month14<1 sec<1 secfact_sales_monthly5,022,794~20 sec~11.5 min

Chapter 6: Power BI Semantic Layer
Import Mode Decision
Power BI Import mode loads all data into memory for fast query response. DirectQuery queries the database live for every interaction.
At 112M daily rows, Import mode would exceed limits. At 5M monthly rows, Import mode is viable and provides significantly better interactivity.
Field Parameters — The CMI Equivalent
The original CMI tool used VBA macros to dynamically change what dimension was displayed on chart axes. Power BI's Field Parameters feature (introduced 2022) replicates this natively without code.
Metric parameter: Toggles all chart measures between Sales and Volume with a single click.
Focus By parameter: Switches chart axis dimension across 12 attributes (Category, Sub-Category, Supplier, Brand, Pack Size Type, Package, Product Description, Store Type, Region, State, City, Store Name).
Combined with dynamic DAX measure titles, this produces the same interactive experience as the original CMI "Focus by" and metric toggle — but implemented natively in Power BI.
DAX Measure Design
All measures stored in a dedicated _Measures table (underscore sorts it to the top of the field list). Key design patterns:

DIVIDE() used throughout instead of / to handle zero denominators gracefully
Share measures use ALL() to remove dimension filter context and calculate against total
ALLSELECTED() used in Top N table measures — respects slicer context but removes visual row filter
Store Count PY explicitly excludes new stores (store[new store] = FALSE()) for apples-to-apples same-store comparison
YOY % measures use conditional formatting (green/red) via Power BI's fx color rules
Field Parameters drive dynamic chart titles via DAX measures wired to visual title fx field


Chapter 7: Report Design
Design Philosophy
The report is designed for two audiences simultaneously:

Hiring managers who may not be deeply technical — they need visual impact and clear storytelling
Technical reviewers who will examine the sophistication of the underlying model

The approach: visually impressive and immediately understandable at the executive level, with analytical depth available for those who look closer.
Layout System
Consistent across all 6 pages:

Navy header (#1F3864) with white title and page navigation buttons
Light gray filter strip with Year/Quarter/Month tiles, Month dropdown, Sales/Volume toggle
Left panel (200px) with 12 dropdown slicers (7 product, 5 store)
Main canvas area for report-specific visuals

Cross-Filtering Over Drill-Down
A deliberate departure from drill-down navigation. Clicking any visual filters all other visuals on the page — a more intuitive interaction model for most business audiences. Hierarchies are present in the model for those who prefer drill-down, but the primary navigation model uses separate pages for different granularities.
Report Pages
Executive Summary: Business health at a glance. Four KPI cards (Total Sales, Sales YOY%, Total Volume, Volume YOY%) with conditional color formatting. Monthly Sales vs Prior Year combo chart (navy bars + amber line). Top 20 products table with Sales, Volume, YOY%, Share%, and Avg Price.
Geographic: Store performance by geography. Bubble map showing all 585 UK store locations sized by sales volume. Regional bar chart. Regional summary table with Sales/Store metric — a category management staple.
Top 10: Dynamic Top N ranking driven by Focus By selector. Bar chart shows CY vs PY bars with YOY% line on secondary axis. Full metrics table below with Sales, Volume, YOY%, and Share%.
Category & Brand: Category donut chart showing sales/volume share. Top brand bar chart. Category-level metrics table with Sales, Sales PY, YOY%, Volume, Volume PY, Vol YOY%, Share%, and Avg Price. Sales/Volume toggle drives both charts and the table simultaneously.
Pricing: Sales & Avg Price per Unit combo chart (navy columns + amber price line, secondary axis). KPI cards for Avg Price and Avg Price YOY% with conditional formatting. Avg Price by Category bar chart. Avg Price by Pack Size Type bar chart — reveals per-transaction pricing dynamics across Single Serve, Large Single, and Multipack formats.
Growth & Trends: CY vs PY trend lines (12 months). Sales/Volume toggle switches both the trend chart and the category comparison chart. CY vs PY by Category clustered bar chart. KPI cards with conditional formatting.

Chapter 8: Known Limitations & Future Iterations
Assortment Efficiency Analysis (Pareto Chart)
The original CMI tool included an Assortment view — a custom Pareto chart showing cumulative sales contribution by product, segmented into 80% / 95% / 100% bands. This was one of the most analytically valuable views in the CMI tool, enabling SKU rationalization decisions.
The DAX measures for a Power BI Pareto implementation are fully written and committed to the repository (Cumulative Metric %, Pareto Band 80/95/100, Focus Item Rank, Focus Total Items). The challenge is constructing the correct visual in Power BI to render the segmented Pareto curve — standard visuals don't support this natively and AppSource Pareto visuals have limitations.
A Power BI Pareto chart is planned for a future iteration of this report.
Growth Forecast
The original CMI Growth Trends view included a sales forecast line derived from a least-squares regression with seasonality adjustment — a genuinely sophisticated analytical feature for its time.
Power BI has a built-in forecast function in its Analytics pane, which uses exponential smoothing with configurable seasonality. However, this feature requires a continuous date or numeric axis. This report uses a text-based month label axis driven by the mart.dim_month table — a deliberate architectural choice to optimize for Import mode performance and clean month labeling across a 12-month window.
Attempts to use a numeric axis (month_sort integer) or a date axis (month_date) both encountered Power BI version compatibility issues with the Analytics pane in the March 2026 release of Power BI Desktop.
A forecasting solution using DAX time intelligence or a custom Python/R visual is planned for a future iteration.

Key Lessons Learned
Technical

BULK INSERT limitations — Cannot accept variable paths. Dynamic SQL with sp_executesql is the correct workaround.
PARSENAME() is limited to 4 parts — STRING_SPLIT() is more flexible for parsing delimited data.
Recursive CTE default limit — MAXRECURSION defaults to 100. Must specify OPTION (MAXRECURSION N) for longer sequences.
Power BI sort by column limitation — Cannot sort a column by another column if the sort column has multiple values for the same display value. Month abbreviations appearing in multiple years cannot be sorted by a year × month composite key — must use month number (1-12) instead.
Azure serverless auto-pause — First connection after pause takes 30-60 seconds. Plan for it in Power BI connection timeout settings.
BCP migration at scale — 112M rows takes 3+ hours at residential upload speeds. Plan accordingly and use batch size parameter (-b 10000) for progress visibility and timeout prevention.
Azure free tier vCore consumption — The initial fact_sales BCP import (112M rows, 3.25 hours) consumed the monthly free tier vCore seconds. Subsequent work required waiting for the monthly reset. Plan cloud migrations to stay within free tier limits or budget for paid tier.
Power BI forecast axis requirements — The built-in forecast function requires a continuous date or numeric axis. Text-based axes (even when backed by numeric sort columns) are not compatible with the Analytics pane forecast feature in current Power BI Desktop releases.

Architectural

Silver layer trade-off — For a single-source pipeline feeding a single mart, silver adds complexity without proportional value. Silver earns its place in production when multiple downstream consumers share a single cleansed layer, or when source data genuinely requires a stable intermediate inspection point.
Aggregation strategy — Choosing the right grain for the reporting layer is as important as any other architectural decision. Monthly × store × product at 5M rows proved optimal for this dataset — preserving full dimensional slicing while enabling Import mode in Power BI.
Document diagnostic queries — The 04.3a script preserving the duplicate UPC investigation is as valuable as the fix itself. It records the decision-making process, not just the outcome.
dim_month as a separate table — Rather than forcing the Power BI axis to use the mart.dim_date daily table or a derived date field, a dedicated mart.dim_month table with 14 rows provides a clean, purpose-built axis table for monthly reporting. This is a common pattern in production monthly reporting models.

Business

Business context drives better engineering — Understanding that "Seasonal" was a promotional subcategory tag rather than a true product hierarchy level led to the correct deduplication strategy. A pure engineer might have applied any deduplication rule; domain knowledge produced the right one.
Design for your audience — The CMI tool was designed for category managers. The Power BI report is designed for hiring managers. Different audiences require different design priorities. Knowing which audience you're designing for is as important as technical execution.
Excel/VBA vs modern BI tooling — The original CMI tool implemented features (Pareto charts, least-squares forecasting, dynamic axis switching) that required sophisticated custom code in Excel/VBA. Power BI replicates most of these natively (Field Parameters for axis switching, built-in forecast) but has its own constraints. Neither platform is universally superior — the right tool depends on the use case, the audience, and the data scale.


Appendix: Script Index
ScriptPurposeKey Technique01.1Staging fact table DDLSingle-column varchar staging01.2Load table DDL—01.3Core store DDL—01.4Core product DDL—02.1Load 53 flat filesDynamic SQL + STRING_SPLIT02.2Load core storeQuoted field CSV handling02.3Load core product—02.4Validation queries228 orphaned UPC check03.1Silver fact loadDate shift +11 years03.2Silver store dimschar(13) removal, new_store_flag03.3Silver product dimspack_size_type derivation03.4Silver indexes5 indexes on fact_sales03.5Silver dim_dateRecursive CTE, MAXRECURSION 50004.1Mart dim_dateQuarter/month sort columns04.2Mart dim_storeFlattened SCD Type 204.3Mart dim_productROW_NUMBER() deduplication04.3aDiagnostic queriesMulti-category subcategory investigation04.4Mart fact_salesSurrogate key resolution via joins04.5Mart indexes5 indexes on fact_sales04.6Mart fact_sales_monthlyMonthly aggregation for Power BI04.7Sort columnsQuarter/month chronological ordering05.1Azure DDLCreate mart schema on Azure05.2Azure BCP migrationExport/import dims + fact_sales07.1Azure completiondim_date columns, dim_month, fact_sales_monthly, indexes06.1DAX measuresAll 30+ measures with comments

Playbook written March–April 2026. Project complete.