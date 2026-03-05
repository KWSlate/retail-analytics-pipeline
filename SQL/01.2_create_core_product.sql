USE [Retail_Analytics]
GO

/****** Object:  Table [core].[Product]    Script Date: 2/27/2026 3:29:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [core].[product](
	[upc] [varchar](50) NOT NULL,
	[dept_nbr] [int] NULL,
	[prime_item_nbr] [varchar](50) NULL,
	[description] [varchar](100) NULL,
	[supplier] [varchar](100) NULL,
	[category] [varchar](100) NULL,
	[subcategory] [varchar](100) NULL,
	[brand] [varchar](100) NULL,
	[package] [varchar](100) NULL,
	[date_created] [datetime2](3) NOT NULL,
	[source_file_name] [varchar](100) NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [core].[Product] ADD  CONSTRAINT [DF__Product__Date_cr__71D1E811]  DEFAULT (sysdatetime()) FOR [Date_Created]
GO

