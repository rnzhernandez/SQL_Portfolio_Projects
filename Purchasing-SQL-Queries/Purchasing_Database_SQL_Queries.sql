--1. How many vendors did the company place orders with that had a credit rating greater than 2?
SELECT COUNT(DISTINCT poh.VendorID) AS VendorCount
FROM Purchasing.PurchaseOrderHeader poh
JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
WHERE v.CreditRating > 2;


--2. Display names of vendors and their preferred status of vendors who live in Washington province.
SELECT v.Name, v.PreferredVendorStatus
FROM Purchasing.Vendor v
JOIN Purchasing.vVendorWithAddresses va ON v.BusinessEntityID = va.BusinessEntityID
WHERE va.StateProvinceName = 'Washington';


--3. How many distinct orders made in 2012 that have been either shipped by “Truck” or “Cargo Ship”? Display also the total quantity.
SELECT COUNT(DISTINCT poh.PurchaseOrderID) AS OrderCount, 
       SUM(pod.OrderQty) AS TotalQuantity
FROM Purchasing.PurchaseOrderHeader poh
JOIN Purchasing.PurchaseOrderDetail pod ON poh.PurchaseOrderID = pod.PurchaseOrderID
JOIN Purchasing.ShipMethod sm ON poh.ShipMethodID = sm.ShipMethodID
WHERE YEAR(poh.OrderDate) = 2012
AND (sm.Name LIKE '%Truck%' OR sm.Name LIKE '%Cargo%');


--4. Display vendors name, state and its latest receipt cost in descending order of both standard price and average lead times.
SELECT v.Name, va.StateProvinceName, pv.LastReceiptCost
FROM Purchasing.ProductVendor pv
JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
JOIN Purchasing.vVendorWithAddresses va ON v.BusinessEntityID = va.BusinessEntityID
ORDER BY pv.StandardPrice DESC, pv.AverageLeadTime DESC;


--5. Calculate the quarter sales of vendors in Washington province. Results must have five columns that named as vendor name, year, quarter, total quantity, and total sales, and displayed in time order.
SELECT v.Name AS VendorName, 
       YEAR(poh.OrderDate) AS Year, 
       DATEPART(QUARTER, poh.OrderDate) AS Quarter,
       SUM(pod.OrderQty) AS TotalQuantity, 
       SUM(pod.LineTotal) AS TotalSales
FROM Purchasing.PurchaseOrderHeader poh
JOIN Purchasing.PurchaseOrderDetail pod ON poh.PurchaseOrderID = pod.PurchaseOrderID
JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
JOIN Purchasing.vVendorWithAddresses va ON v.BusinessEntityID = va.BusinessEntityID
WHERE va.StateProvinceName = 'Washington'
GROUP BY v.Name, YEAR(poh.OrderDate), DATEPART(QUARTER, poh.OrderDate)
ORDER BY Year, Quarter;


--6. Who are the two most used vendors based on quantity of orders?
SELECT TOP 2 v.Name, SUM(pod.OrderQty) AS TotalOrderedQuantity
FROM Purchasing.PurchaseOrderDetail pod
JOIN Purchasing.PurchaseOrderHeader poh ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
GROUP BY v.Name
ORDER BY TotalOrderedQuantity DESC;


--7. The company wants to choose the best vendor for each shipping type to process orders faster that can improve the company sales and reputation. To help the manager suggest these vendors, you are required to propose a criterion/criteria with justification, and write code to find the answer. Your answer must not be an empty table.
SELECT sm.Name AS ShippingType, 
       v.Name AS BestVendor, 
       MIN(pv.AverageLeadTime) AS MinLeadTime
FROM Purchasing.PurchaseOrderHeader poh
JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
JOIN Purchasing.ShipMethod sm ON poh.ShipMethodID = sm.ShipMethodID
GROUP BY sm.Name, v.Name
ORDER BY sm.Name, MinLeadTime;


--8. Based on the answer of Question 4.7, display the vendor that have sold the highest orders and lowest lead time that is the best vendor.
SELECT TOP 1 v.Name AS BestVendor, 
              SUM(pod.OrderQty) AS TotalOrders, 
              MIN(pv.AverageLeadTime) AS MinLeadTime
FROM Purchasing.PurchaseOrderDetail pod
JOIN Purchasing.PurchaseOrderHeader poh ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
GROUP BY v.Name
ORDER BY TotalOrders DESC, MinLeadTime ASC;


--9 The company wants to know the most popular efficient and price effective vendor. You are required to propose a criterion/criteria to define, and write code to find the answer. Your answer must not be an empty table.
SELECT TOP 1 v.Name AS BestVendor, 
              SUM(pod.OrderQty) AS TotalOrders, 
              MIN(pv.AverageLeadTime) AS MinLeadTime, 
              MIN(pv.StandardPrice) AS BestPrice
FROM Purchasing.PurchaseOrderDetail pod
JOIN Purchasing.PurchaseOrderHeader poh ON pod.PurchaseOrderID = poh.PurchaseOrderID
JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
GROUP BY v.Name
ORDER BY TotalOrders DESC, MinLeadTime ASC, BestPrice ASC;


-- 10 Based on the answer of Question 4.9, what is the average order fulfillment cost and time?
WITH BestVendor AS (
    SELECT TOP 1 v.Name AS BestVendor
    FROM Purchasing.PurchaseOrderDetail pod
    JOIN Purchasing.PurchaseOrderHeader poh ON pod.PurchaseOrderID = poh.PurchaseOrderID
    JOIN Purchasing.Vendor v ON poh.VendorID = v.BusinessEntityID
    JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
    GROUP BY v.Name
    ORDER BY SUM(pod.OrderQty) DESC, MIN(pv.AverageLeadTime) ASC, MIN(pv.StandardPrice) ASC
)
SELECT v.Name AS BestVendor, 
       AVG(pv.LastReceiptCost) AS AvgFulfillmentCost, 
       AVG(pv.AverageLeadTime) AS AvgFulfillmentTime
FROM Purchasing.ProductVendor pv
JOIN Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
WHERE v.Name = (SELECT BestVendor FROM BestVendor)
GROUP BY v.Name;
