USE [Retail_Analytics]
GO

/****** Object:  Table [core].[Store]    Script Date: 2/27/2026 3:30:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [core].[Store](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Store_Nbr] [varchar](25) NOT NULL,
	[Store_Name] [varchar](200) NULL,
	[Store_Type] [varchar](100) NULL,
	[City] [varchar](100) NULL,
	[State] [char](2) NULL,
	[Zip_Code] [varchar](10) NULL,
	[Focus1] [varchar](100) NULL,
	[Focus2] [varchar](100) NULL,
	[Focus3] [varchar](100) NULL,
	[Sales] [decimal](18, 2) NULL,
	[Units] [int] NULL,
	[Status] [varchar](50) NULL,
	[Date_Created] [date] NULL,
 CONSTRAINT [PK_Store] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

