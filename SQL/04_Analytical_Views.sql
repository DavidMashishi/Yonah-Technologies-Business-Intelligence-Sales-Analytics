/*
    Gold analytical views for Power BI / reporting.
*/

-- Monthly Sales Performance

CREATE OR ALTER VIEW gold.MonthlySalesPerformance
AS

WITH MonthlySales AS
(
    SELECT
        d.Year,
        d.MonthNumber,
        d.MonthName,
        d.YearMonth,
        SUM(f.Quantity) AS Total_Units,
        COUNT(DISTINCT f.Order_ID) AS Total_Orders,
        SUM(f.Revenue) AS Revenue,
        SUM(f.Cost) AS Cost,
        SUM(f.Profit) AS Profit
    FROM fact.Sales f
    INNER JOIN dim.Date d
        ON f.DateKey = d.DateKey
    GROUP BY
        d.Year,
        d.MonthNumber,
        d.MonthName,
        d.YearMonth
),

CalculatedMetrics AS
(
    SELECT
        *,
        
        Revenue / NULLIF(Total_Orders, 0) AS Average_Order_Value,
        Profit / NULLIF(Revenue, 0)AS Profit_Margin,
        LAG(Revenue) OVER(ORDER BY Year, MonthNumber) AS Previous_Month_Revenue,
        LAG(Revenue) OVER(PARTITION BY MonthNumber ORDER BY Year) AS Previous_Year_Revenue,
        SUM(Revenue) OVER(ORDER BY Year, MonthNumber
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Revenue

    FROM MonthlySales
)

SELECT
    Year,
    MonthNumber,
    MonthName,
    YearMonth,
    Total_Units,
    Total_Orders,
    Revenue,
    Cost,
    Profit,
    Average_Order_Value,
    Profit_Margin,
    Previous_Month_Revenue,
    Previous_Year_Revenue,
    CASE
        WHEN Previous_Month_Revenue IS NULL
             OR Previous_Month_Revenue = 0
        THEN NULL
        ELSE
            (Revenue - Previous_Month_Revenue)
            / Previous_Month_Revenue
    END AS MoM_Growth,
    CASE
        WHEN Previous_Year_Revenue IS NULL
             OR Previous_Year_Revenue = 0
        THEN NULL
        ELSE
            (Revenue - Previous_Year_Revenue)
            / Previous_Year_Revenue
    END AS YoY_Growth,
    Running_Revenue
FROM CalculatedMetrics;
GO

-- Regional Reformance

CREATE OR ALTER VIEW gold.RegionalPerformance
AS

WITH RegionalMetrics AS
(
    SELECT
        c.Region,
        SUM(f.Quantity) AS Total_Units,
        COUNT(DISTINCT f.Order_ID) AS Total_Orders,
        SUM(f.Revenue) AS Revenue,
        SUM(f.Cost) AS Cost,
        SUM(f.Profit) AS Profit
    FROM fact.Sales f
    INNER JOIN dim.Customer c
    ON f.CustomerKey = c.CustomerKey
    GROUP BY c.Region
),

RegionalWithMetrics AS
(
    SELECT
        *,

        Revenue / NULLIF(Total_Orders, 0) AS Average_Order_Value,
        Profit / NULLIF(Revenue, 0) AS Profit_Margin,
        Revenue / NULLIF(SUM(Revenue) OVER (), 0) AS Revenue_Contribution,
        RANK() OVER( ORDER BY Revenue DESC) AS Revenue_Rank,
        RANK() OVER (ORDER BY Profit DESC) AS Profit_Rank
	FROM RegionalMetrics)

SELECT
    Region,
    Total_Units,
    Total_Orders,
    Revenue,
    Cost,
    Profit,
    Average_Order_Value,
    Profit_Margin,
    Revenue_Contribution,
    Revenue_Rank,
    Profit_Rank
FROM RegionalWithMetrics;
GO

-- Customer Analytics

CREATE OR ALTER VIEW gold.CustomerAnalytics
AS

WITH CustomerMetrics AS
(
    SELECT
        c.CustomerKey,
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Age,
        c.Customer_Type,
        c.Region,
        COUNT(DISTINCT f.Order_ID) AS Total_Orders,
        SUM(f.Quantity) AS Total_Units,
        SUM(f.Revenue) AS Revenue,
        SUM(f.Cost) AS Cost,
        SUM(f.Profit) AS Profit,
        MIN(d.FullDate) AS First_Purchase_Date,
        MAX(d.FullDate) AS Last_Purchase_Date
    FROM fact.Sales f
    INNER JOIN dim.Customer c
        ON f.CustomerKey = c.CustomerKey
    INNER JOIN dim.Date d
        ON f.DateKey = d.DateKey
    GROUP BY
        c.CustomerKey,
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Age,
        c.Customer_Type,
        c.Region
),

CustomerWithMetrics AS
(
    SELECT
        *,
        Revenue / NULLIF(Total_Orders, 0)
            AS Average_Order_Value,
        DATEDIFF(DAY,First_Purchase_Date,Last_Purchase_Date) AS Customer_Lifetime_Days,
        CASE
            WHEN Total_Orders > 1
                THEN 'Repeat Customer'
            ELSE 'One-Time Customer'
        END AS Customer_Status
    FROM CustomerMetrics
)

SELECT
    CustomerKey,
    Customer_ID,
    Customer_Name,
    Customer_Age,
    Customer_Type,
    Region,
    Total_Orders,
    Total_Units,
    Revenue,
    Cost,
    Profit,
    Average_Order_Value,
    First_Purchase_Date,
    Last_Purchase_Date,
    Customer_Lifetime_Days,
    Customer_Status
FROM CustomerWithMetrics;
GO

-- CustomerRFM

CREATE OR ALTER VIEW gold.CustomerRFM
AS

WITH CustomerRFMBase AS
(
    SELECT
        c.CustomerKey,
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Type,
        c.Region,
        DATEDIFF
        (DAY,MAX(d.FullDate),(SELECT MAX(FullDate) FROM dim.Date)) AS Recency,
	COUNT(DISTINCT f.Order_ID) AS Frequency,
        SUM(f.Revenue) AS Monetary
    FROM fact.Sales f
    INNER JOIN dim.Customer c
        ON f.CustomerKey = c.CustomerKey
    INNER JOIN dim.Date d
        ON f.DateKey = d.DateKey
    GROUP BY
        c.CustomerKey,
        c.Customer_ID,
        c.Customer_Name,
        c.Customer_Type,
        c.Region
),

RFMScores AS
(
    SELECT
        *,

        NTILE(5) OVER
        (ORDER BY Recency DESC) AS Recency_Score,
        NTILE(5) OVER(ORDER BY Frequency ASC) AS Frequency_Score,
        NTILE(5) OVER(ORDER BY Monetary ASC) AS Monetary_Score
    FROM CustomerRFMBase
)
SELECT
    CustomerKey,
    Customer_ID,
    Customer_Name,
    Customer_Type,
    Region,
    Recency,
    Frequency,
    Monetary,
    Recency_Score,
    Frequency_Score,
    Monetary_Score,

    CAST(Recency_Score AS VARCHAR(1))
        + CAST(Frequency_Score AS VARCHAR(1))
        + CAST(Monetary_Score AS VARCHAR(1))
        AS RFM_Score,
    CASE
        WHEN Recency_Score >= 4
         AND Frequency_Score >= 4
         AND Monetary_Score >= 4
            THEN 'Champions'
        WHEN Recency_Score >= 3
         AND Frequency_Score >= 4
         AND Monetary_Score >= 3
            THEN 'Loyal Customers'
        WHEN Recency_Score >= 4
         AND Frequency_Score >= 2
         AND Monetary_Score >= 2
            THEN 'Potential Loyalists'
        WHEN Recency_Score <= 2
         AND Frequency_Score >= 3
         AND Monetary_Score >= 3
            THEN 'At Risk'
        WHEN Recency_Score <= 2
         AND Frequency_Score <= 2
         AND Monetary_Score >= 3
            THEN 'Needs Attention'
        WHEN Recency_Score <= 2
         AND Frequency_Score <= 2
         AND Monetary_Score <= 2
            THEN 'Lost Customers'
        ELSE 'Other'
    END AS RFM_Segment
FROM RFMScores;
GO


-- Product Performance 
CREATE OR ALTER VIEW gold.vw_Product_Performance AS
SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,
    SUM(f.Revenue) AS Revenue,
    SUM(f.Profit) AS Profit,
    SUM(f.Quantity) AS Units_Sold,
    COUNT(DISTINCT f.Order_ID) AS Transactions,
    COUNT(DISTINCT f.CustomerKey) AS Customers,
    CAST(SUM(f.Profit) / NULLIF(SUM(f.Revenue),0) AS DECIMAL(9,4)) AS Profit_Margin
FROM fact.Sales f
JOIN dim.Product p ON p.ProductKey = f.ProductKey
GROUP BY p.Product_ID, p.Product_Name, p.Category;
GO




