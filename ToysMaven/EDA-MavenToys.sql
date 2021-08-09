/*
Maven Toys - Data Exploration 
Skills used: Views, CTE's, Joins, Temp Tables, Aggregate Functions, Converting Data Types, Top, Pivot Table
*/

USE ToysDataset
GO

--- How many cities have store?  
SELECT DISTINCT(Store_City) AS Cities
FROM stores
GO

--- How many stores have sales? 
SELECT COUNT(DISTINCT(Store_ID)) AS Stores_with_Sales
FROM sales
GO

--- Total Sales by City

		---Create a view that contains a column for the total sales
CREATE VIEW View_Sales_Total AS
SELECT sa.Sale_ID,
sa.Date,
sa.Store_ID, 
sa.Product_ID,
pr.Product_Category,
sa.Units * pr.Product_Price AS Total
FROM sales AS sa
JOIN products AS pr
ON sa.Product_ID = pr.Product_ID
GO

		--- Join 'Sales_Total' with the store table to view the sales distribution by city
SELECT st.Store_City,
CONVERT(INT, SUM(v.Total)) AS Total_Sales
FROM View_Sales_Total AS v
JOIN stores AS st
ON st.Store_ID = v.Store_ID
GROUP BY st.Store_City
ORDER BY Total_Sales DESC
GO

		---Sales in "Ciudad de México"
SELECT st.Store_ID,
st.Store_Name,
CONVERT(INT, SUM(Units * Product_Price)) AS Sales_Money,
COUNT(Sale_ID) AS Sales_Tickets,
CONVERT(NUMERIC(5,2), (SUM(Units * Product_Price) / COUNT(Sale_ID))) AS Avg_Ticket
FROM sales AS sa
JOIN stores AS st
ON st.Store_ID = sa.Store_ID
JOIN products AS p
ON sa.Product_ID = p.Product_ID
WHERE Store_City = 'Ciudad de Mexico' 
GROUP BY st.Store_ID, st.Store_Name
ORDER BY Sales_Money DESC
GO

--- Sales by product category 
SELECT Product_Category,
CAST(SUM(Total) AS INT) AS Sales_Category
FROM View_Sales_Total
GROUP BY Product_Category
ORDER BY Sales_Category DESC
GO

--- Stock on hand value by category
SELECT Store_ID,
i.Product_ID,
Stock_On_Hand,
Stock_On_Hand * Product_Cost AS Stock_Valuated
INTO #Stock_Valuation 
FROM inventory AS i
JOIN products AS p
ON i.Product_ID = p.Product_ID

SELECT Product_Category,
CONVERT(INT,SUM(Stock_Valuated)) AS Stock_Category
FROM #Stock_Valuation AS s
JOIN products AS p
ON s.Product_ID = p.Product_ID
GROUP BY Product_Category
ORDER BY Stock_Category DESC
GO


---How much money is tied up in inventory at the toy stores?-
SELECT SUM(i.Stock_On_Hand * p.Product_Cost) AS Inventory_Value
FROM inventory AS i
LEFT JOIN products AS p
ON i.Product_ID = p.Product_ID
GO


--- Top 5 Products in Sales 
		--- Product ID 
SELECT TOP 5 p.Product_ID
FROM View_Sales_Total AS v
JOIN products AS p
ON v.Product_ID = p.Product_ID
GROUP BY P.Product_ID
ORDER BY SUM(Total) DESC
GO

		--- Product ID and Name
SELECT TOP 5 p.Product_ID,
p.Product_Name
FROM View_Sales_Total AS v
JOIN products AS p
ON v.Product_ID = p.Product_ID
GROUP BY P.Product_Name, p.Product_ID
ORDER BY SUM(Total) DESC
GO


--- Top 5 stores with the lowest stock of best-selling products
SELECT TOP 5 i.Store_ID ,Store_Name
FROM inventory AS i
JOIN stores AS s
ON i.Store_ID = s.Store_ID
WHERE Product_ID IN (
SELECT TOP 5 p.Product_ID
FROM View_Sales_Total AS v
JOIN products AS p
ON v.Product_ID = p.Product_ID
GROUP BY P.Product_ID
ORDER BY SUM(Total) DESC
)
GROUP BY i.Store_ID, Store_Name
ORDER BY SUM(Stock_On_Hand) ASC
GO


--- Top 5 products with less stock on hand
SELECT TOP 5 Product_ID, SUM(Stock_on_Hand) AS Stock
FROM inventory
GROUP BY Product_ID
ORDER BY Stock ASC
GO

--- Global profit numbers by category
WITH SalesAndCost AS(
SELECT  Sale_ID,
Product_Category,
Units * Product_Price AS Sale,
Units * Product_Cost AS Cost
FROM sales AS s
LEFT JOIN products AS p
ON S.Product_ID = p.Product_ID)

SELECT Product_Category,
CAST(SUM(Sale) AS INT) AS Total_Sales,
CONVERT(INT,((SUM(Sale)/SUM(Cost)) - 1)*100) AS Margin_Percentage
FROM SalesAndCost
GROUP BY Product_Category
ORDER BY Total_Sales DESC
GO

---Sales by month and category 
WITH pvt_table AS(
SELECT Product_Category,
MONTH(Date) AS TheMonth,
CAST(SUM(Total) AS NUMERIC(10,2)) AS Total
FROM View_Sales_Total
GROUP BY Product_Category,MONTH(Date)
)

SELECT *
FROM pvt_table
PIVOT (SUM(Total)
FOR TheMonth in ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS my_pvt
ORDER BY Product_Category 
GO
