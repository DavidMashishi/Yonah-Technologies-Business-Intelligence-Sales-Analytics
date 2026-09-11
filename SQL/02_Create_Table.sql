-- 02_Create_Tables


CREATE TABLE raw.Customers
(
    Customer_ID    VARCHAR(20)  NOT NULL,
    Customer_Name  VARCHAR(100) NOT NULL,
    Customer_Age   INT          NULL,
    Customer_Type  VARCHAR(30)  NULL,
    Region         VARCHAR(50)  NULL
);
GO


USE YonahBI;
GO

BULK INSERT raw.Customers
FROM 'C:\Users\David Tshego\Desktop\Data Analytics\001 PROJECTS\YonahTechnologiesSalesProject\Datasets\Customers.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

-- Validation Check
SELECT COUNT(*) AS Customer_Count FROM raw.Customers;  	

======================================================
-- Products
=====================================================
raw.Products


USE YonahBI;
GO

CREATE TABLE raw.Products
(
    Product_ID      VARCHAR(20)   NOT NULL,
    Product_Name    VARCHAR(100)  NOT NULL,
    Category        VARCHAR(50)   NULL,
    Base_Price      DECIMAL(18,2) NULL,
    Base_Margin     DECIMAL(18,2) NULL
);
GO


USE YonahBI;
GO

BULK INSERT raw.Products
FROM 'C:\Users\David Tshego\Desktop\Data Analytics\001 PROJECTS\YonahTechnologiesSalesProject\Datasets\Products.csv'
WITH
(
    FORMAT = 'CSV',
    FIELDQUOTE = '"',
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

-- Validation Check
SELECT COUNT(*) AS Product_Count FROM raw.Products;
SELECT * FROM raw.Products;

==========================================================
-- Sales
==========================================================


USE YonahBI;
GO

CREATE TABLE raw.Sales
(
    Order_ID          VARCHAR(30)   NOT NULL,
    Order_Date        DATE          NOT NULL,
    Year              INT           NOT NULL,
    Quarter           VARCHAR(10)   NULL,
    Year_Month        VARCHAR(20)   NULL,
    Month_Name        VARCHAR(20)   NULL,
    Day_of_Week       VARCHAR(20)   NULL,
    Customer_ID       VARCHAR(20)   NOT NULL,
    Customer_Name     VARCHAR(100)  NULL,
    Customer_Age      INT           NULL,
    Customer_Type     VARCHAR(30)   NULL,
    Region            VARCHAR(50)   NULL,
    Product_ID        VARCHAR(20)   NOT NULL,
    Product_Name      VARCHAR(100)  NULL,
    Category          VARCHAR(50)   NULL,
    Quantity          INT           NULL,
    Unit_Price        DECIMAL(18,2) NULL,
    Discount_Pct      DECIMAL(8,4)  NULL,
    Revenue           DECIMAL(18,2) NULL,
    Cost              DECIMAL(18,2) NULL,
    Profit            DECIMAL(18,2) NULL,
    Gross_Margin_Pct  DECIMAL(8,4)  NULL
);
GO

-- BULK INSERT

USE YonahBI;
GO

BULK INSERT raw.Sales
FROM 'C:\Users\David Tshego\Desktop\Data Analytics\001 PROJECTS\YonahTechnologiesSalesProject\Datasets\Sales_Data.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO

-- Validation Check 

 SELECT COUNT(*) AS Sales_Count FROM raw.Sales;
 SELECT TOP 10 * FROM raw.Sales;
 SELECT
    SUM(Quantity) AS Total_Units,
    SUM(Revenue) AS Total_Revenue,
    SUM(Cost) AS Total_Cost,
    SUM(Profit) AS Total_Profit
FROM raw.Sales;

