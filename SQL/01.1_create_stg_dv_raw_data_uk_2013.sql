USE [Retail_Analytics]
GO

/****** Object:  Table [stg].[DV_Raw_Data_UK_2013]    Script Date: 2/27/2026 3:28:49 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [stg].[DV_Raw_Data_UK_2013](
	[DAY_DT] [datetime] NULL,
	[DAY_MAIN_DSC] [date] NULL,
	[RET_STORE_NBR_ID] [varchar](25) NULL,
	[UPC_TXT] [varchar](50) NULL,
	[WJXBFS1] [decimal](18, 4) NULL,
	[WJXBFS2] [decimal](18, 4) NULL,
	[WJXBFS3] [decimal](18, 4) NULL,
	[WJXBFS4] [decimal](18, 4) NULL,
	[Date_Created] [datetime2](7) NULL
) ON [PRIMARY]
GO

