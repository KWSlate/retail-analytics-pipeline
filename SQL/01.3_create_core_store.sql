USE [Retail_Analytics]
GO

/****** Object:  Table [core].[Store]    Script Date: 2/27/2026 3:30:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [core].[Store](
	[store_nbr] [varchar](25) NOT NULL,
	[store_name] [varchar](200) NULL,
	[city] [varchar](100) NULL,
	[state] [char](2) NULL,
	[zip_code] [varchar](10) NULL,
	[store_type] [varchar](100) NULL,
	[focus2] [varchar](100) NULL,
	[status] [varchar](50) NULL,
	[date_created] datetime2(3) NULL,
	[source_file_name] varchar(100) NULL,
 CONSTRAINT [PK_Store] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


