/* ============================================================================
   CHINOOK REFERENCE QUERIES  —  companion to the 5-Day SQL Study Plan
   ============================================================================

   Every query below was executed against a real chinook.db and returns the
   results shown in the "-- Result:" comments. Use these to CHECK your own
   attempts — try each case study cold first, then compare.

   ----------------------------------------------------------------------------
   IMPORTANT — TWO NAMING CONVENTIONS EXIST. Check yours first.
   ----------------------------------------------------------------------------
   These queries use the lerocha/chinook-database SQLite file, which uses
   SINGULAR, PascalCase table names:
       Customer, Invoice, InvoiceLine, Track, Genre, Album, Artist, Employee

   The other very common distribution (sqlitetutorial.net) uses PLURAL,
   snake_case table names. If you downloaded that one, do a find-and-replace:

       Invoice      -> invoices
       InvoiceLine  -> invoice_items      (and InvoiceLineId -> InvoiceLineId)
       Track        -> tracks
       Genre        -> genres
       Customer     -> customers
       Employee     -> employees
       Album        -> albums
       Artist       -> artists

   Column names (CustomerId, InvoiceId, Total, ReportsTo, SupportRepId, ...)
   are the SAME in both. Run this to see YOUR table names:
       SELECT name FROM sqlite_master WHERE type='table';

   Key relationships you'll use:
     Invoice.CustomerId     -> Customer.CustomerId
     InvoiceLine.InvoiceId  -> Invoice.InvoiceId
     InvoiceLine.TrackId    -> Track.TrackId
     Track.GenreId          -> Genre.GenreId
     Customer.SupportRepId  -> Employee.EmployeeId   (the sales rep)
     Employee.ReportsTo     -> Employee.EmployeeId   (the manager — self-ref)
   ============================================================================ */


/* ============================================================================
   DAY 1 — BASICS & INTERMEDIATE  (aggregation, GROUP BY, HAVING)
   Case study: where is the revenue concentrated?
   ============================================================================ */

-- 1.1  Revenue by country. Single table. WHERE filters rows; HAVING filters
--      GROUPS (after aggregation). Note you can't put SUM() in WHERE.
SELECT BillingCountry            AS country,
       COUNT(*)                  AS invoices,
       ROUND(SUM(Total), 2)      AS revenue,
       ROUND(AVG(Total), 2)      AS avg_invoice
FROM Invoice
GROUP BY BillingCountry
HAVING SUM(Total) > 40            -- keep only countries above a revenue floor
ORDER BY revenue DESC;
-- Result: USA 523.06 | Canada 303.96 | France 195.10 | Brazil 190.10 ... (15 rows)

-- 1.2  Top 10 customers by lifetime spend. Still single-table — group by the
--      foreign key, no join needed yet.
SELECT CustomerId,
       COUNT(*)                  AS invoices,
       ROUND(SUM(Total), 2)      AS lifetime_spend
FROM Invoice
GROUP BY CustomerId
ORDER BY lifetime_spend DESC
LIMIT 10;

-- 1.3  Revenue by genre  (PREVIEW: this one needs joins — that's Day 3).
--      Revenue lives on InvoiceLine (UnitPrice * Quantity); genre lives on
--      Track. So you must walk InvoiceLine -> Track -> Genre.
SELECT g.Name                                   AS genre,
       ROUND(SUM(il.UnitPrice * il.Quantity), 2) AS revenue
FROM InvoiceLine il
JOIN Track t ON t.TrackId = il.TrackId
JOIN Genre g ON g.GenreId = t.GenreId
GROUP BY g.Name
ORDER BY revenue DESC
LIMIT 10;
-- Result: Rock 826.65 | Latin 382.14 | Metal 261.36 | Alternative & Punk 241.56 ...


/* ============================================================================
   DAY 2 — FILTERING, FUNCTIONS, OPERATORS  (CASE, strings, dates, NULL)
   Case study: segment customers and clean labels for reporting.
   ============================================================================ */

-- 2.1  Customer value tiers with CASE + string cleaning (UPPER/TRIM).
--      CASE is your SQL if/elif/else. Thresholds picked from the real spend
--      distribution (min 36.64, max 49.62 — tightly clustered).
SELECT c.CustomerId,
       c.FirstName || ' ' || c.LastName AS customer,
       UPPER(TRIM(c.Country))           AS country,
       ROUND(SUM(i.Total), 2)           AS spend,
       CASE
           WHEN SUM(i.Total) >= 40 THEN 'High'
           WHEN SUM(i.Total) >= 38 THEN 'Medium'
           ELSE 'Low'
       END                              AS value_tier
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId
ORDER BY spend DESC;
-- Result: Helena Holý 49.62 High | Richard Cunningham 47.62 High ... (59 rows)

-- 2.2  Customer tenure with date functions. Dates are 'YYYY-MM-DD HH:MM:SS'
--      strings; julianday() lets you do arithmetic. CAST(... AS INT) truncates.
SELECT c.CustomerId,
       c.FirstName || ' ' || c.LastName AS customer,
       MIN(i.InvoiceDate)               AS first_purchase,
       CAST( (julianday(MAX(i.InvoiceDate)) - julianday(MIN(i.InvoiceDate))) / 30
             AS INT )                    AS tenure_months
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId
ORDER BY tenure_months DESC;

-- 2.3  THE NULL TRAP (this is your Day 2 LinkedIn post).
--      49 of 59 customers have a NULL Company. A naive "not equal" filter
--      SILENTLY DROPS every NULL row, because NULL <> 'x' is NULL, not TRUE.
SELECT COUNT(*) FROM Customer
WHERE Company <> 'Embraer - Empresa Brasileira de Aeronáutica S.A.';
-- Result: 9   <-- 50 rows vanished! (49 nulls + the 1 matched company)

-- The fix: handle NULL explicitly.
SELECT COUNT(*) FROM Customer
WHERE Company <> 'Embraer - Empresa Brasileira de Aeronáutica S.A.'
   OR Company IS NULL;
-- Result: 58   <-- correct (59 total minus the 1 excluded company)

-- 2.4  COALESCE gives NULLs a sensible default for reporting.
SELECT CustomerId,
       COALESCE(Company, 'Individual') AS account_type,
       COALESCE(State,   'N/A')        AS state
FROM Customer;


/* ============================================================================
   DAY 3 — JOINS, SELF-JOINS, ANTI-JOINS, SUBQUERIES
   Case study: sales-rep performance, the org hierarchy, and what's missing.
   ============================================================================ */

-- 3.1  Revenue per support rep. Three-table join: which rep 'owns' the
--      customer (Customer.SupportRepId), then that customer's invoices.
SELECT e.EmployeeId,
       e.FirstName || ' ' || e.LastName AS support_rep,
       COUNT(DISTINCT c.CustomerId)     AS customers,
       ROUND(SUM(i.Total), 2)           AS revenue
FROM Employee e
JOIN Customer c ON c.SupportRepId = e.EmployeeId
JOIN Invoice  i ON i.CustomerId   = c.CustomerId
GROUP BY e.EmployeeId
ORDER BY revenue DESC;
-- Result: Jane Peacock 833.04 | Margaret Park 775.40 | Steve Johnson 720.16

-- 3.2  SELF-JOIN: attach each employee's manager. The same table appears
--      twice with different aliases (e = employee, m = manager). LEFT JOIN so
--      the top boss (ReportsTo = NULL) still appears.
SELECT e.FirstName || ' ' || e.LastName AS employee,
       e.Title,
       m.FirstName || ' ' || m.LastName AS manager
FROM Employee e
LEFT JOIN Employee m ON e.ReportsTo = m.EmployeeId
ORDER BY e.EmployeeId;
-- Result: Andrew Adams / General Manager / (none); Nancy Edwards / Sales Manager / Andrew Adams ...

-- 3.3a  ANTI-JOIN #1: customers who never bought. Pattern = LEFT JOIN then
--       keep only rows where the right side is NULL (no match).
SELECT c.CustomerId, c.FirstName || ' ' || c.LastName AS customer
FROM Customer c
LEFT JOIN Invoice i ON i.CustomerId = c.CustomerId
WHERE i.InvoiceId IS NULL;
-- Result: 0 rows  <-- every Chinook customer has bought something. Not a bug!
--         The pattern is correct; this data just has no unmatched customers.

-- 3.3b  ANTI-JOIN #2 (same pattern, on data that DOES have unmatched rows):
--       tracks that have never been sold.
SELECT t.TrackId, t.Name
FROM Track t
LEFT JOIN InvoiceLine il ON il.TrackId = t.TrackId
WHERE il.InvoiceLineId IS NULL;
-- Result: 1,519 tracks in the catalogue have never appeared on an invoice.

-- 3.4  CORRELATED SUBQUERY: customers who spent more than the average customer
--      IN THEIR OWN COUNTRY. The inner query references c.Country from the
--      outer row — picture it re-running once per customer.
SELECT c.CustomerId,
       c.FirstName || ' ' || c.LastName AS customer,
       c.Country,
       ROUND(SUM(i.Total), 2)           AS spend
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId
HAVING SUM(i.Total) > (
    SELECT AVG(cust_total)
    FROM (
        SELECT SUM(i2.Total) AS cust_total
        FROM Customer c2
        JOIN Invoice i2 ON i2.CustomerId = c2.CustomerId
        WHERE c2.Country = c.Country        -- <- the correlation
        GROUP BY c2.CustomerId
    )
)
ORDER BY c.Country, spend DESC;
-- Result: 13 customers beat their country's per-customer average.


/* ============================================================================
   DAY 4 — WINDOW FUNCTIONS  (aggregate WITHOUT collapsing rows)
   Case study: revenue over time, and top-N within each group.
   ============================================================================ */

-- 4.1  Monthly revenue with a running total, month-over-month change (LAG),
--      and a 3-month moving average (a frame: current row + 2 preceding).
--      The WITH block just names the monthly rollup (full CTEs are Day 5).
WITH monthly AS (
    SELECT strftime('%Y-%m', InvoiceDate) AS month,
           SUM(Total)                     AS revenue
    FROM Invoice
    GROUP BY strftime('%Y-%m', InvoiceDate)
)
SELECT month,
       ROUND(revenue, 2)                                          AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month), 2)               AS running_total,
       ROUND(revenue - LAG(revenue) OVER (ORDER BY month), 2)     AS mom_change,
       ROUND(AVG(revenue) OVER (ORDER BY month
                 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)    AS moving_avg_3mo
FROM monthly
ORDER BY month;
-- Result (first rows):
--   2021-01  35.64  35.64   (null)  35.64   <- LAG is NULL on the first row
--   2021-02  37.62  73.26    1.98   36.63
--   2021-03  37.62 110.88    0.00   36.96

-- 4.2  TOP 3 tracks per genre by revenue — the classic "top-N-per-group".
--      PARTITION BY genre = restart the numbering for each genre. This example
--      also SHOWS the tie behaviour: many tracks tie on revenue, so
--      ROW_NUMBER assigns 1,2,3 arbitrarily while RANK/DENSE_RANK give 1,1,1.
WITH track_rev AS (
    SELECT g.Name                            AS genre,
           t.Name                            AS track,
           SUM(il.UnitPrice * il.Quantity)   AS revenue
    FROM InvoiceLine il
    JOIN Track t ON t.TrackId = il.TrackId
    JOIN Genre g ON g.GenreId = t.GenreId
    GROUP BY g.GenreId, t.TrackId
),
ranked AS (
    SELECT genre, track, revenue,
           ROW_NUMBER() OVER (PARTITION BY genre ORDER BY revenue DESC, track) AS rn,
           RANK()       OVER (PARTITION BY genre ORDER BY revenue DESC)        AS rnk,
           DENSE_RANK() OVER (PARTITION BY genre ORDER BY revenue DESC)        AS dense_rnk
    FROM track_rev
)
SELECT genre, track, ROUND(revenue, 2) AS revenue, rn, rnk, dense_rnk
FROM ranked
WHERE rn <= 3
ORDER BY genre, rn;

-- 4.3  Rank each customer within their country by spend (no rows lost — the
--      per-customer detail stays; the rank is just an added column).
SELECT c.Country,
       c.FirstName || ' ' || c.LastName AS customer,
       ROUND(SUM(i.Total), 2)           AS spend,
       RANK() OVER (PARTITION BY c.Country ORDER BY SUM(i.Total) DESC) AS rank_in_country
FROM Customer c
JOIN Invoice i ON i.CustomerId = c.CustomerId
GROUP BY c.CustomerId
ORDER BY c.Country, rank_in_country;


/* ============================================================================
   DAY 5 — COMMON TABLE EXPRESSIONS  (readability + recursion)
   Case study: a recursive org chart, and a customer cohort/retention table.
   ============================================================================ */

-- 5.1  RECURSIVE CTE: the full employee org chart with depth. Read it as
--      induction: the ANCHOR is the top boss (ReportsTo IS NULL); the
--      RECURSIVE member repeatedly finds everyone reporting to the level above.
--      'path' both builds the tree and gives us a natural sort order.
WITH RECURSIVE org AS (
    -- anchor: base case
    SELECT EmployeeId,
           FirstName || ' ' || LastName AS name,
           Title, ReportsTo,
           0                            AS depth,
           FirstName || ' ' || LastName AS path
    FROM Employee
    WHERE ReportsTo IS NULL
    UNION ALL
    -- recursive step: reports of the people already found
    SELECT e.EmployeeId,
           e.FirstName || ' ' || e.LastName,
           e.Title, e.ReportsTo,
           org.depth + 1,
           org.path || ' > ' || e.FirstName || ' ' || e.LastName
    FROM Employee e
    JOIN org ON e.ReportsTo = org.EmployeeId
)
SELECT depth,
       substr('                    ', 1, depth * 2) || name AS org_chart,
       Title
FROM org
ORDER BY path;
-- Result:
--   0  Andrew Adams          General Manager
--   1    Michael Mitchell    IT Manager
--   2      Laura Callahan     IT Staff
--   2      Robert King        IT Staff
--   1    Nancy Edwards       Sales Manager
--   2      Jane Peacock       Sales Support Agent  ...

-- 5.2  CUSTOMER COHORT / RETENTION. Three CTEs chained into a pipeline:
--      (1) each customer's cohort = their first-purchase month;
--      (2) every month each customer was active;
--      (3) months elapsed between cohort and activity.
--      Then count distinct active customers per (cohort, offset). Offset 0 is
--      the cohort's starting size; later offsets show retention.
WITH first_purchase AS (
    SELECT CustomerId,
           MIN(strftime('%Y-%m', InvoiceDate)) AS cohort_month
    FROM Invoice
    GROUP BY CustomerId
),
activity AS (
    SELECT DISTINCT
           i.CustomerId,
           fp.cohort_month,
           strftime('%Y-%m', i.InvoiceDate) AS active_month
    FROM Invoice i
    JOIN first_purchase fp ON fp.CustomerId = i.CustomerId
),
offsets AS (
    SELECT cohort_month,
           ( CAST(substr(active_month, 1, 4) AS INT) * 12
           + CAST(substr(active_month, 6, 2) AS INT) )
         - ( CAST(substr(cohort_month, 1, 4) AS INT) * 12
           + CAST(substr(cohort_month, 6, 2) AS INT) ) AS month_offset,
           CustomerId
    FROM activity
)
SELECT cohort_month,
       month_offset,
       COUNT(DISTINCT CustomerId) AS active_customers
FROM offsets
GROUP BY cohort_month, month_offset
ORDER BY cohort_month, month_offset;
-- Result: 2021-01 cohort starts with 6 customers at offset 0, then trickles
--         down in later months — a retention curve in long format. Pivot it
--         (cohort as rows, offset as columns) in your write-up for the classic
--         triangular cohort chart.

/* ============================================================================
   CAPSTONE IDEA: re-run 4.1 (running total) or 5.2 (cohorts) on a real,
   messy public dataset (NYC taxi, an e-commerce set, Olympics). The technique
   is identical; the value is showing you can handle real data cleaning.
   ============================================================================ */
