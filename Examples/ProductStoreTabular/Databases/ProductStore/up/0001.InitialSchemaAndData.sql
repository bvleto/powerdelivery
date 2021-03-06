SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Customers](
	[CustomerID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED 
(
	[CustomerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Manufacturers](
	[ManufacturerID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
 CONSTRAINT [PK_Manufacturers] PRIMARY KEY CLUSTERED 
(
	[ManufacturerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [OrderItems](
	[OrderItemID] [int] IDENTITY(1,1) NOT NULL,
	[OrderID] [int] NOT NULL,
	[ProductID] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
 CONSTRAINT [PK_OrderItems] PRIMARY KEY CLUSTERED 
(
	[OrderItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Orders](
	[OrderID] [int] IDENTITY(1,1) NOT NULL,
	[CustomerID] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastModifiedOn] [datetime] NULL,
 CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED 
(
	[OrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Products](
	[ProductID] [int] IDENTITY(1,1) NOT NULL,
	[ManufacturerID] [int] NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[Price] [money] NOT NULL,
 CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED 
(
	[ProductID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET IDENTITY_INSERT [Customers] ON 

INSERT [Customers] ([CustomerID], [Name]) VALUES (1, N'John Doe')
INSERT [Customers] ([CustomerID], [Name]) VALUES (2, N'Mary Jane')
INSERT [Customers] ([CustomerID], [Name]) VALUES (3, N'Dave Jones')
INSERT [Customers] ([CustomerID], [Name]) VALUES (4, N'Bob Johnson')
SET IDENTITY_INSERT [Customers] OFF
SET IDENTITY_INSERT [Manufacturers] ON 

INSERT [Manufacturers] ([ManufacturerID], [Name]) VALUES (1, N'ACME Inc.')
INSERT [Manufacturers] ([ManufacturerID], [Name]) VALUES (2, N'PARTCO')
SET IDENTITY_INSERT [Manufacturers] OFF
SET IDENTITY_INSERT [Orders] ON 

INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (2, 1, CAST(0x0000A31301274583 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (3, 2, CAST(0x0000A313012746A6 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (4, 2, CAST(0x0000A3130127475A AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (5, 1, CAST(0x0000A3130127480A AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (6, 3, CAST(0x0000A3130127B8EC AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (7, 2, CAST(0x0000A3130127BA11 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (8, 2, CAST(0x0000A3130127BAB3 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (9, 4, CAST(0x0000A3130127BB7C AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (10, 4, CAST(0x0000A3130127BC6A AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (11, 4, CAST(0x0000A3130127BD22 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (12, 2, CAST(0x0000A3130127BE15 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (13, 1, CAST(0x0000A3130127BFB5 AS DateTime), NULL)
INSERT [Orders] ([OrderID], [CustomerID], [CreatedOn], [LastModifiedOn]) VALUES (14, 3, CAST(0x0000A3130127C52C AS DateTime), NULL)
SET IDENTITY_INSERT [Orders] OFF
SET IDENTITY_INSERT [Products] ON 

INSERT [Products] ([ProductID], [ManufacturerID], [Name], [Price]) VALUES (1, 1, N'Widget 1', 15.0000)
INSERT [Products] ([ProductID], [ManufacturerID], [Name], [Price]) VALUES (2, 1, N'Widget 2', 15.0000)
INSERT [Products] ([ProductID], [ManufacturerID], [Name], [Price]) VALUES (3, 2, N'Sprocket 1', 12.0000)
INSERT [Products] ([ProductID], [ManufacturerID], [Name], [Price]) VALUES (4, 2, N'Sprocket 2', 10.0000)
SET IDENTITY_INSERT [Products] OFF
CREATE NONCLUSTERED INDEX [IX_Manufacturer_Name] ON [Manufacturers]
(
	[ManufacturerID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [Orders] ADD  CONSTRAINT [DF_Orders_CreatedOn]  DEFAULT (getdate()) FOR [CreatedOn]
GO
ALTER TABLE [OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Orders] FOREIGN KEY([OrderID])
REFERENCES [Orders] ([OrderID])
GO
ALTER TABLE [OrderItems] CHECK CONSTRAINT [FK_OrderItems_Orders]
GO
ALTER TABLE [OrderItems]  WITH CHECK ADD  CONSTRAINT [FK_OrderItems_Products] FOREIGN KEY([ProductID])
REFERENCES [Products] ([ProductID])
GO
ALTER TABLE [OrderItems] CHECK CONSTRAINT [FK_OrderItems_Products]
GO
ALTER TABLE [Orders]  WITH CHECK ADD  CONSTRAINT [FK_Orders_Customers] FOREIGN KEY([CustomerID])
REFERENCES [Customers] ([CustomerID])
GO
ALTER TABLE [Orders] CHECK CONSTRAINT [FK_Orders_Customers]
GO
ALTER TABLE [Products]  WITH CHECK ADD  CONSTRAINT [FK_Products_Manufacturers] FOREIGN KEY([ManufacturerID])
REFERENCES [Manufacturers] ([ManufacturerID])
GO
ALTER TABLE [Products] CHECK CONSTRAINT [FK_Products_Manufacturers]
GO