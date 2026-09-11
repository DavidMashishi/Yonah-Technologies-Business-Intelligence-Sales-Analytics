/*
    Data quality and reconciliation checks
*/

USE YonahBI;
GO

SELECT 'Fact row count' AS Check_Name, COUNT(*) AS Result FROM fact.Sales;
SELECT 'Customer count' AS Check_Name, COUNT(*) AS Result FROM dim.Customer;
SELECT 'Product count' AS Check_Name, COUNT(*) AS Result FROM dim.Product;
SELECT 'Date count' AS Check_Name, COUNT(*) AS Result FROM dim.Date;

SELECT
    SUM(Revenue) AS Revenue,
    SUM(Profit) AS Profit,
    SUM(Quantity) AS Units
FROM fact.Sales;

SELECT
    COUNT(*) AS Duplicate_Order_IDs
FROM (
    SELECT Order_ID
    FROM fact.Sales
    GROUP BY Order_ID
    HAVING COUNT(*) > 1
) x;

SELECT
    COUNT(*) AS Invalid_Financial_Rows
FROM fact.Sales
WHERE Revenue < 0 OR Cost < 0 OR Profit < 0 OR Quantity <= 0;

SELECT
    c.Region,
    COUNT(DISTINCT f.CustomerKey) AS Customers,
    COUNT(DISTINCT f.Order_ID) AS Transactions,
    SUM(f.Revenue) AS Revenue
FROM fact.Sales f
JOIN dim.Customer c ON c.CustomerKey = f.CustomerKey
GROUP BY c.Region
ORDER BY Revenue DESC;