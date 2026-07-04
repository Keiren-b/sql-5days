-- **Business question:** 
-- *"Which genres and which countries drive the most revenue, and how does average invoice size vary by country?"*

-- This is actually 3 different questions that I'll answer in turn 
    -- Question 1: Which genres drive the most revenue
    -- Question 2: Which countries drive the most revenue
    -- Question 3: Average invoice size by country

-- Question 1:

SELECT 
Genre.Name,
SUM(InvoiceLine.UnitPrice * InvoiceLine.Quantity) as Revenue
FROM InvoiceLine
LEFT JOIN Track 
ON InvoiceLine.TrackId=Track.TrackId
LEFT JOIN Genre
ON Track.GenreId=Genre.GenreId
GROUP BY Genre.GenreId
ORDER BY Revenue DESC


-- Question 2:

SELECT BillingCountry, SUM(Total) as Revenue FROM Invoice 
GROUP BY BillingCountry 
ORDER BY Revenue DESC

-- Question 3
SELECT BillingCountry, AVG(Total) as AverageRevenue FROM Invoice 
GROUP BY BillingCountry 
ORDER BY AverageRevenue DESC

--Deliverables:
-- Revenue by genre (join isn't needed yet if you use `invoice_items` cleverly — or keep it single-table and do revenue by country/customer first).
-- Revenue by country with `SUM`, average invoice value with `AVG`, and a `HAVING` filter for countries above a revenue threshold.
-- A short written insight: where is the money concentrated?