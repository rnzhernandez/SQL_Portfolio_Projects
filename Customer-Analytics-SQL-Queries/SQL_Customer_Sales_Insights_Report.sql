-- 1. Which customers have demonstrated consistent purchasing behavior throughout the year, and how frequently are they engaging in transactions on a monthly basis?
SELECT 
    [Dimension].[Customer].[Customer Key],
    [Dimension].[Customer].[Customer],
    COUNT(DISTINCT [Dimension].[Date].[Month]) AS PurchaseMonths,
    COUNT([Fact].[Sale].[WWI Invoice ID]) AS TotalPurchases
FROM 
    [Fact].[Sale]
INNER JOIN 
    [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
INNER JOIN 
    [Dimension].[Date] 
    ON [Fact].[Sale].[Invoice Date Key] = [Dimension].[Date].[Date]
GROUP BY 
    [Dimension].[Customer].[Customer Key],
    [Dimension].[Customer].[Customer]
ORDER BY 
    PurchaseMonths DESC;

--2. Who are our most loyal customers based on the volume of their purchases, and how much revenue have they generated over time?
SELECT TOP 10
    [Dimension].[Customer].[Customer],
    COUNT([Fact].[Sale].[WWI Invoice ID]) AS PurchaseCount,
    SUM([Fact].[Sale].[Total Including Tax]) AS TotalSpent
FROM 
    [Fact].[Sale]
INNER JOIN 
    [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
GROUP BY 
    [Dimension].[Customer].[Customer]
ORDER BY 
    PurchaseCount DESC;


--3. What is the average purchase value per customer across different buying groups, and which groups contribute most significantly to overall sales?
SELECT 
    [Dimension].[Customer].[Buying Group],
    AVG([Fact].[Sale].[Total Including Tax]) AS AvgSpend,
    COUNT(DISTINCT [Dimension].[Customer].[Customer Key]) AS CustomerCount
FROM 
    [Fact].[Sale]
INNER JOIN 
    [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
GROUP BY 
    [Dimension].[Customer].[Buying Group]
ORDER BY 
    AvgSpend DESC;

--4. How has total revenue evolved on a month-to-month basis across multiple years, and what seasonal or cyclical patterns can be observed? 
SELECT 
    [Dimension].[Date].[Calendar Year],
    [Dimension].[Date].[Month],
    SUM([Fact].[Sale].[Total Including Tax]) AS MonthlyRevenue
FROM 
    [Fact].[Sale]
INNER JOIN 
    [Dimension].[Date] 
    ON [Fact].[Sale].[Invoice Date Key] = [Dimension].[Date].[Date]
GROUP BY 
    [Dimension].[Date].[Calendar Year],
    [Dimension].[Date].[Month]
ORDER BY 
    [Dimension].[Date].[Calendar Year],
    [Dimension].[Date].[Month];


-- 5. Which customers have not made any purchases since 2016, and are therefore at risk of churn or already inactive?
SELECT 
    [Dimension].[Customer].[Customer],
    MAX([Dimension].[Date].[Date]) AS LastPurchaseDate
FROM 
    [Fact].[Sale]
INNER JOIN 
    [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
INNER JOIN 
    [Dimension].[Date] 
    ON [Fact].[Sale].[Invoice Date Key] = [Dimension].[Date].[Date]
GROUP BY 
    [Dimension].[Customer].[Customer]
HAVING 
    MAX([Dimension].[Date].[Date]) < '2016-01-01'
ORDER BY 
    LastPurchaseDate ASC;

-- 6. For each customer, what is the span between their first and most recent purchases, and how many years have they remained active?
SELECT 
    c.[Customer],
    MIN(d.[Calendar Year]) AS FirstPurchaseYear,
    MAX(d.[Calendar Year]) AS LastPurchaseYear,
    DATEDIFF(YEAR, 
        MIN(CONVERT(DATE, d.[Date])), 
        MAX(CONVERT(DATE, d.[Date]))
    ) AS ActiveYears
FROM 
    [Fact].[Sale] fs
INNER JOIN 
    [Dimension].[Customer] c ON fs.[Customer Key] = c.[Customer Key]
INNER JOIN 
    [Dimension].[Date] d ON fs.[Invoice Date Key] = d.[Date]
GROUP BY 
    c.[Customer]
ORDER BY 
    ActiveYears DESC;

--7. How has each customer’s annual spending changed over time, and what is their year-over-year growth trajectory?
SELECT 
    [Dimension].[Customer].[Customer],
    [Dimension].[Date].[Calendar Year],
    SUM([Fact].[Sale].[Total Including Tax]) AS YearlySales,
    LAG(SUM([Fact].[Sale].[Total Including Tax])) OVER (
        PARTITION BY [Dimension].[Customer].[Customer]
        ORDER BY [Dimension].[Date].[Calendar Year]
    ) AS PreviousYearSales,
    (SUM([Fact].[Sale].[Total Including Tax]) - 
     LAG(SUM([Fact].[Sale].[Total Including Tax])) OVER (
        PARTITION BY [Dimension].[Customer].[Customer]
        ORDER BY [Dimension].[Date].[Calendar Year]
    )) * 1.0 / 
     LAG(SUM([Fact].[Sale].[Total Including Tax])) OVER (
        PARTITION BY [Dimension].[Customer].[Customer]
        ORDER BY [Dimension].[Date].[Calendar Year]
    ) AS YoYGrowth
FROM [Fact].[Sale]
INNER JOIN [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
INNER JOIN [Dimension].[Date] 
    ON [Fact].[Sale].[Invoice Date Key] = [Dimension].[Date].[Date]
GROUP BY [Dimension].[Customer].[Customer], [Dimension].[Date].[Calendar Year];

-- 8. Which customer orders have individually exceeded $500,000 in value, and which clients consistently generate high-value transactions?
SELECT 
    [Fact].[Sale].[WWI Invoice ID],
    [Dimension].[Customer].[Customer],
    SUM([Fact].[Sale].[Total Including Tax]) AS OrderTotal
FROM [Fact].[Sale]
INNER JOIN [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
GROUP BY [Fact].[Sale].[WWI Invoice ID], [Dimension].[Customer].[Customer]
HAVING SUM([Fact].[Sale].[Total Including Tax]) > 500000
ORDER BY OrderTotal DESC;

-- 9. Which product categories deliver the highest profit margins when associated with customer orders, and how do these categories compare in terms of total revenue and profit contribution?
SELECT 
    [Dimension].[Customer].[Category],
    SUM([Fact].[Sale].[Profit]) AS TotalProfit,
    SUM([Fact].[Sale].[Total Including Tax]) AS TotalRevenue,
    (SUM([Fact].[Sale].[Profit]) * 1.0 / 
     SUM([Fact].[Sale].[Total Including Tax])) AS ProfitMargin
FROM [Fact].[Sale]
INNER JOIN [Dimension].[Customer] 
    ON [Fact].[Sale].[Customer Key] = [Dimension].[Customer].[Customer Key]
GROUP BY [Dimension].[Customer].[Category]
ORDER BY ProfitMargin DESC;

-- 10. How does sales performance vary by state/province and quarter, and which regions are driving or underperforming in terms of revenue generation over time?
SELECT 
    [Dimension].[City].[State Province],
    [Dimension].[Date].[Quarter],
    SUM([Fact].[Sale].[Total Including Tax]) AS TotalSales
FROM [Fact].[Sale]
INNER JOIN [Dimension].[City] 
    ON [Fact].[Sale].[City Key] = [Dimension].[City].[City Key]
INNER JOIN [Dimension].[Date] 
    ON [Fact].[Sale].[Invoice Date Key] = [Dimension].[Date].[Date]
GROUP BY [Dimension].[City].[State Province], [Dimension].[Date].[Quarter]
ORDER BY [Dimension].[City].[State Province], [Dimension].[Date].[Quarter];