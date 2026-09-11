
-- 03_Load Data

--dim.Customer

USE YonahBI;
GO

CREATE TABLE dim.Customer
(
    CustomerKey    INT IDENTITY(1,1) NOT NULL,
    Customer_ID    VARCHAR(20)       NOT NULL,
    Customer_Name  VARCHAR(100)      NOT NULL,
    Customer_Age   INT               NULL,
    Customer_Type  VARCHAR(30)       NULL,
    Region         VARCHAR(50)       NULL,

    CONSTRAINT PK_dim_Customer
        PRIMARY KEY (CustomerKey),

    CONSTRAINT UQ_dim_Customer_Customer_ID
        UNIQUE (Customer_ID)
);
GO


INSERT INTO dim.Customer
(
    Customer_ID,
    Customer_Name,
    Customer_Age,
    Customer_Type,
    Region
)
SELECT
    Customer_ID,
    Customer_Name,
    Customer_Age,
    Customer_Type,
    Region
FROM raw.Customers;
GO


-- dim.Product

USE YonahBI;
GO

CREATE TABLE dim.Product
(
    ProductKey    INT IDENTITY(1,1) NOT NULL,
    Product_ID    VARCHAR(20)       NOT NULL,
    Product_Name  VARCHAR(100)      NOT NULL,
    Category      VARCHAR(50)       NULL,
    Base_Price    DECIMAL(18,2)     NULL,
    Base_Margin   DECIMAL(18,2)     NULL,

    CONSTRAINT PK_dim_Product
        PRIMARY KEY (ProductKey),

    CONSTRAINT UQ_dim_Product_Product_ID
        UNIQUE (Product_ID)
);
GO

Populate dim.Product

INSERT INTO dim.Product
(
    Product_ID,
    Product_Name,
    Category,
    Base_Price,
    Base_Margin
)
SELECT
    Product_ID,
    Product_Name,
    Category,
    Base_Price,
    Base_Margin
FROM raw.Products;
GO

-- dim.Date

USE YonahBI;
GO

CREATE TABLE dim.Date
(
    DateKey        INT          NOT NULL,
    FullDate       DATE         NOT NULL,
    Year           INT          NOT NULL,
    QuarterNumber  INT          NOT NULL,
    QuarterName    VARCHAR(10)  NOT NULL,
    MonthNumber    INT          NOT NULL,
    MonthName      VARCHAR(20)  NOT NULL,
    YearMonth      CHAR(7)      NOT NULL,
    WeekNumber     INT          NOT NULL,
    DayOfMonth     INT          NOT NULL,
    DayName        VARCHAR(20)  NOT NULL,
    DayOfWeek      INT          NOT NULL,
    IsWeekend      BIT          NOT NULL,

    CONSTRAINT PK_dim_Date
        PRIMARY KEY (DateKey)
);
GO



DECLARE @StartDate DATE = '2022-01-01';
DECLARE @EndDate   DATE = '2025-12-31';

;WITH DateSeries AS
(
    SELECT @StartDate AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < @EndDate
)
INSERT INTO dim.Date
(
    DateKey,
    FullDate,
    Year,
    QuarterNumber,
    QuarterName,
    MonthNumber,
    MonthName,
    YearMonth,
    WeekNumber,
    DayOfMonth,
    DayName,
    DayOfWeek,
    IsWeekend
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)) AS DateKey,
    FullDate,
    YEAR(FullDate),
    DATEPART(QUARTER, FullDate),
    'Q' + CAST(DATEPART(QUARTER, FullDate) AS VARCHAR(1)),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    CONVERT(CHAR(7), FullDate, 120),
    DATEPART(ISO_WEEK, FullDate),
    DAY(FullDate),
    DATENAME(WEEKDAY, FullDate),
    DATEPART(WEEKDAY, FullDate),
    CASE
        WHEN DATENAME(WEEKDAY, FullDate) IN ('Saturday', 'Sunday')
            THEN 1
        ELSE 0
    END
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

-- Fact Sales

USE YonahBI;
GO

CREATE TABLE fact.Sales
(
    SalesKey          BIGINT IDENTITY(1,1) NOT NULL,
    
    Order_ID          VARCHAR(30)          NOT NULL,
    DateKey           INT                  NOT NULL,
    CustomerKey       INT                  NOT NULL,
    ProductKey        INT                  NOT NULL,

    Quantity          INT                  NULL,
    Unit_Price        DECIMAL(18,2)        NULL,
    Discount_Pct      DECIMAL(8,4)         NULL,
    Revenue           DECIMAL(18,2)        NULL,
    Cost              DECIMAL(18,2)        NULL,
    Profit             DECIMAL(18,2)        NULL,
    Gross_Margin_Pct  DECIMAL(8,4)         NULL,

    CONSTRAINT PK_fact_Sales
        PRIMARY KEY (SalesKey),

    CONSTRAINT FK_fact_Sales_Date
        FOREIGN KEY (DateKey)
        REFERENCES dim.Date(DateKey),

    CONSTRAINT FK_fact_Sales_Customer
        FOREIGN KEY (CustomerKey)
        REFERENCES dim.Customer(CustomerKey),

    CONSTRAINT FK_fact_Sales_Product
        FOREIGN KEY (ProductKey)
        REFERENCES dim.Product(ProductKey)
);
GO


INSERT INTO fact.Sales
(
    Order_ID,
    DateKey,
    CustomerKey,
    ProductKey,
    Quantity,
    Unit_Price,
    Discount_Pct,
    Revenue,
    Cost,
    Profit,
    Gross_Margin_Pct
)
SELECT
    s.Order_ID,
    d.DateKey,
    c.CustomerKey,
    p.ProductKey,
    s.Quantity,
    s.Unit_Price,
    s.Discount_Pct,
    s.Revenue,
    s.Cost,
    s.Profit,
    s.Gross_Margin_Pct
FROM raw.Sales s
INNER JOIN dim.Date d
    ON s.Order_Date = d.FullDate
INNER JOIN dim.Customer c
    ON s.Customer_ID = c.Customer_ID
INNER JOIN dim.Product p
    ON s.Product_ID = p.Product_ID;
GO
