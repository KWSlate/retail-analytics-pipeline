USE [Retail_Analytics]
GO

/****** Object:  Table [core].[Product]    Script Date: 2/27/2026 3:29:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [core].[Product](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Dept_Nbr] [int] NULL,
	[UPC] [varchar](50) NOT NULL,
	[Supplier] [varchar](100) NULL,
	[Category] [varchar](100) NULL,
	[Subcategory] [varchar](100) NULL,
	[Brand] [varchar](100) NULL,
	[Package] [varchar](100) NULL,
	[Product_Desc] [varchar](255) NULL,
	[Sales] [decimal](18, 4) NULL,
	[Units] [decimal](18, 4) NULL,
	[Avg_Retail] [decimal](18, 4) NULL,
	[Date_Created] [datetime2](7) NOT NULL,
 CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [core].[Product] ADD  CONSTRAINT [DF__Product__Date_cr__71D1E811]  DEFAULT (sysdatetime()) FOR [Date_Created]
GO

