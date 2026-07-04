# SQL in 5 Days — A Portfolio-Building Study Plan for the Career Transitioner

*For someone who already thinks in data (pandas, stats, analysis) but has never formally learned SQL. The goal isn't just to pass an interview screen — it's to walk away with a coherent public portfolio and a "learning in public" LinkedIn trail.*

---

## How this plan works

Five days, five lessons, five case studies — all built on **one dataset** so your work reads as a single analytical narrative instead of five disconnected exercises.

Each day has four parts, in this order:

1. **Learn** — the concept, anchored to what you already know from pandas/dplyr.
2. **Pen & paper** — a specific by-hand drill *before* you touch a keyboard. This is where the understanding actually forms, and it doubles as LinkedIn content.
3. **Code + case study** — a real business question you answer on the dataset and commit to your portfolio.
4. **Post** — a concrete LinkedIn angle for the day.

**Suggested daily cadence (~2–3 hours):** 30–45 min pen & paper → 60–90 min coding the case study → 20–30 min writing it up + posting.

---

## Setup (do this once, before Day 1)

### The dataset: Chinook (your "spine")

Chinook models a digital music store. Tables you'll live in: `customers`, `invoices`, `invoice_items`, `tracks`, `albums`, `artists`, `genres`, `employees` (with a self-referencing manager hierarchy — gold for self-joins and recursive CTEs).

- **Get it:** search "chinook database sqlite github" and download `chinook.db`. Ports exist for PostgreSQL and MySQL too.
- **Why Chinook and not "real" data for the lessons?** It's clean enough that you fight the *concept*, not the data cleaning — and it's employer-recognized. You'll add real, messy public data in the Day 5 capstone, which is where the "real data" portfolio signal comes from.

### Your environment (pick one lane)

- **Fastest, zero-setup (recommended to start):** **DB Browser for SQLite** + `chinook.db`. Modern SQLite supports window functions and CTEs, so this plan runs end-to-end with no compromises.
- **Resume-grade (level up when ready):** **DBeaver** (free, universal DB client) connected to **PostgreSQL** on a free cloud instance (**Neon** or **Supabase**). Postgres is the dialect most job postings assume.

### Your portfolio home: GitHub

Create a repo — e.g. `sql-in-5-days` — with this structure:

```
sql-in-5-days/
├── README.md                 # overview + what you learned + links to each day
├── data/                     # chinook.db or a setup script
├── day1-aggregations/
│   ├── README.md             # business question → approach → query → result → insight
│   ├── query.sql
│   └── result.png            # screenshot of the output table
├── day2-segmentation/
├── day3-joins-and-hierarchy/
├── day4-window-functions/
├── day5-cte-analytics/
└── capstone-realworld/
```

Each day's `README.md` is a mini case study: **the business question**, your **approach**, the **query**, a **result screenshot**, and 2–3 sentences of **insight**. That write-up is what turns a `.sql` file into a portfolio piece.

### Your LinkedIn sharing tool: DB Fiddle

**db-fiddle.com** lets you paste a schema + query and get a runnable, shareable link. Drop that link in a post so people can click and run your query themselves. Pair it with a **photo of your handwritten pen-and-paper work** — that combination (by-hand reasoning + runnable code) is distinctive and performs well.

---

## The pen-and-paper method (the meta-technique)

SQL is *declarative*: you describe the result you want; the engine figures out how to get it. That's precisely why analysts who already think procedurally in pandas get tripped up. The fix is to hand-simulate what the engine does.

Three drawing habits you'll use all week:

- **Trace the logical execution order.** SQL does *not* run in the order you write it. It runs: **FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT.** Write a query, then redraw the table as it exists *after each clause*. This single habit explains 80% of "why doesn't my query work" moments (e.g., why you can't use a `SELECT` alias in `WHERE`).
- **Draw tables as grids and match rows.** For joins, physically draw both tables and line up matching rows. For window functions, draw the frame boundaries around each row.
- **Draw CTEs as labeled boxes.** Each box is an intermediate table; arrows show what feeds what. A complex query becomes a readable pipeline.

Photograph this work. It's your most authentic LinkedIn content — nobody can fake understanding they've drawn out by hand.

---

# Day 1 — Basics & Intermediate Concepts

### Learn
One framing idea first. A SQL table is a **set of rows** (records), each with the same **columns** (fields). SQL is *declarative and set-based*: rather than looping over rows like you would in Python, you describe the result set you want and the engine produces it. Nearly everything today is one of three operations — **filtering** rows (which rows), **projecting** columns (which columns), or **aggregating** (collapsing many rows into summary numbers).

Here's what each keyword does, walked through in the order the engine actually evaluates them — which, as you'll see, is *not* the order you write them:

- **`FROM`** — names the table(s) to read. It's the starting point: the raw set of rows everything else operates on. Evaluated first, even though you write it second.
- **`WHERE`** — filters *individual rows*. It tests a boolean condition against each row and keeps only those where the condition is TRUE. This runs *before* grouping, so `WHERE` sees raw rows, not aggregates — you cannot put `SUM(...)` in a `WHERE`.
- **`GROUP BY`** — collapses rows into groups that share the same value(s) in the listed column(s). After grouping, each group becomes one output row. This is the engine behind all "per-category" analysis: revenue *per country*, orders *per customer*.
- **Aggregate functions** — **`COUNT`**, **`SUM`**, **`AVG`**, **`MIN`**, **`MAX`** — reduce the many rows in each group to a single number. `COUNT(*)` counts rows; `COUNT(col)` counts only non-NULL values in that column (a subtle but real difference). With no `GROUP BY`, an aggregate collapses the *entire* table into one row.
- **`HAVING`** — filters *groups*, using conditions on aggregates. It's "the `WHERE` for groups" and runs *after* `GROUP BY`. Rule of thumb: filter raw rows with `WHERE` (cheaper, happens first), filter aggregated results with `HAVING`.
- **`SELECT`** — chooses which columns and expressions to return (this is *projection*). It can return plain columns, computed expressions (`price * quantity`), or aggregates. It runs *after* grouping, which is why any non-aggregated column in `SELECT` must also appear in the `GROUP BY`.
- **`DISTINCT`** — removes duplicate rows from the result, leaving unique combinations of the selected columns. `SELECT DISTINCT country` is how you ask "what are the unique values?"
- **`ORDER BY`** — sorts the final result, ascending (`ASC`, the default) or descending (`DESC`). It runs near the end, so it *can* reference aliases and aggregates defined in `SELECT`.
- **`LIMIT`** — caps how many rows come back (`LIMIT 10` for a top-10). It's the very last step, applied after sorting.
- **Aliases** (`AS`) — rename a column or table for the query. `SUM(Total) AS revenue` gives the output a clean name; `FROM Invoice AS i` gives the table a short handle you'll lean on constantly once joins arrive.

**The mental model that ties it together: logical order of execution.** You *write* the clauses in one order but the engine *evaluates* them in another:

`FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT`

This one fact explains most Day 1 confusion: why you can't filter on an aggregate in `WHERE` (grouping hasn't happened yet), why you *can* sort by a `SELECT` alias in `ORDER BY` (SELECT already ran), and why `HAVING` and `WHERE` aren't interchangeable.

**Translating from what you know:**

| You already know (pandas) | SQL |
|---|---|
| `df[df.total > 5]` | `WHERE total > 5` |
| `df.groupby('genre').agg(...)` | `GROUP BY genre` + aggregates |
| filtering *after* a groupby | `HAVING` |
| `df.sort_values(...).head(10)` | `ORDER BY ... LIMIT 10` |
| `df['x'].unique()` | `SELECT DISTINCT x` |

### Pen & paper
Draw a tiny 6-row `invoices`-style table by hand (columns: country, total). Now hand-execute this query **clause by clause**, redrawing the table after each step:

```
SELECT country, SUM(total) AS revenue
FROM invoices
WHERE total > 1
GROUP BY country
HAVING SUM(total) > 5
ORDER BY revenue DESC;
```

Write out: the rows surviving `WHERE`, then the groups formed by `GROUP BY`, then which groups survive `HAVING`, then the final sorted output. When you can do this cold, you understand aggregation.

### Case study → `day1-aggregations/`
**Business question:** *"Which genres and which countries drive the most revenue, and how does average invoice size vary by country?"*

Deliverables:
- Revenue by genre (join isn't needed yet if you use `invoice_items` cleverly — or keep it single-table and do revenue by country/customer first).
- Revenue by country with `SUM`, average invoice value with `AVG`, and a `HAVING` filter for countries above a revenue threshold.
- A short written insight: where is the money concentrated?

### LinkedIn post
> **Hook:** "SQL runs your query in a completely different order than you write it — and once I saw the real order, everything clicked."
>
> Show the 6-clause execution order. Include a photo of your hand-traced table evolving clause by clause. Close with: *Day 1 of 5, learning SQL in public.* Link the DB Fiddle.

---

# Day 2 — Advanced Filtering, Functions & Operators

### Learn
Day 1 worked on whole rows and groups. Day 2 works on **expressions** — the logic you apply *within* a row to filter, transform, and reshape values. Two mental models carry the day: richer boolean logic in `WHERE`, and **three-valued logic** (the `NULL` trap).

**Filtering, in more depth:**

- **`AND` / `OR` / `NOT`** combine conditions. Precedence matters: `NOT` binds tightest, then `AND`, then `OR`. So `A OR B AND C` means `A OR (B AND C)` — rarely what you intended. **Use parentheses** to make intent explicit.
- **`IN (...)`** tests membership in a set: `country IN ('USA','Canada')` is shorthand for a chain of `OR`s.
- **`BETWEEN x AND y`** tests an *inclusive* range — `Total BETWEEN 5 AND 10` includes both endpoints. Works for numbers and dates.
- **`LIKE`** does text pattern matching with two wildcards: **`%`** matches any run of characters, **`_`** matches exactly one. `Email LIKE '%@gmail.com'` finds Gmail addresses; `Name LIKE 'A_a%'` matches names starting with A, any single letter, then a.

**`NULL` and three-valued logic — the concept that trips up every newcomer.** `NULL` is not zero and not an empty string; it means "unknown." Because of that, SQL logic has *three* outcomes, not two: TRUE, FALSE, and NULL. Any comparison *with* a NULL returns NULL — `NULL = NULL` is not TRUE, it's NULL. And `WHERE` only keeps rows where the condition is TRUE, so rows evaluating to NULL are silently dropped. That's why `WHERE country != 'USA'` quietly discards every row where `country` is NULL. Test for null explicitly with **`IS NULL`** / **`IS NOT NULL`** — never `= NULL`.

**Transforming values:**

- **`CASE`** is SQL's `if/elif/else`, and it's an *expression* (it returns a value), so it can live inside `SELECT`, `ORDER BY`, even inside an aggregate. The searched form — `CASE WHEN cond THEN x WHEN cond2 THEN y ELSE z END` — is what you'll use to bucket, relabel, and branch. The first matching `WHEN` wins; if none match and there's no `ELSE`, you get NULL.
- **String functions**: **`||`** (or `CONCAT`) joins text; **`UPPER`/`LOWER`** change case; **`TRIM`** removes surrounding whitespace; **`SUBSTR(s, start, len)`** extracts part of a string; **`REPLACE`** swaps substrings; **`LENGTH`** counts characters. This is your text-cleaning toolkit.
- **Date/time functions** differ by database, but the ideas are universal: extract a part of a date (year, month), compute the gap between two dates, and format dates for grouping. In SQLite you'll use **`strftime('%Y-%m', date)`** to bucket by month and **`julianday()`** for day-level arithmetic.
- **`CAST(value AS type)`** converts between types — text to integer, float to int (which truncates toward zero), and so on.

**Handling nulls gracefully:**

- **`COALESCE(a, b, c)`** returns the first non-NULL argument — ideal for defaults: `COALESCE(Company, 'Individual')`.
- **`NULLIF(a, b)`** returns NULL when `a = b` — most often used to dodge divide-by-zero: `x / NULLIF(y, 0)`.

**Translating from what you know:**

| pandas | SQL |
|---|---|
| `df.col.isin(['USA','Canada'])` | `col IN ('USA','Canada')` |
| `df.col.str.contains('gmail')` | `col LIKE '%gmail%'` |
| `df.col.isna()` | `col IS NULL` |
| `np.where` / `apply` with if/else | `CASE WHEN ... THEN ... ELSE ... END` |
| `df.col.fillna('x')` | `COALESCE(col, 'x')` |
| `df.col.str.upper()` | `UPPER(col)` |
| `df.col.astype(int)` | `CAST(col AS INT)` |

### Pen & paper
Two drills:

1. **NULL truth table.** By hand, evaluate `TRUE AND NULL`, `FALSE AND NULL`, `TRUE OR NULL`, `NULL = NULL`, and `col != 'X'` when `col` is null. Then hand-filter a 5-row table with `WHERE country != 'USA'` where one row is null — watch the null row silently disappear. Now fix it with `WHERE country != 'USA' OR country IS NULL`.
2. **CASE ladder.** Write a `CASE` that buckets customer spend into `High / Medium / Low` and hand-evaluate it against 5 sample values, including a boundary value, to check your `<` vs `<=` logic.

### Case study → `day2-segmentation/`
**Business question:** *"Segment customers into value tiers and clean up inconsistent country labels for reporting."*

Deliverables:
- A `CASE` expression assigning each customer to a spend tier.
- String/date functions to standardize country names and compute customer tenure (months since first purchase).
- `COALESCE` to handle missing fields gracefully.
- Insight: what share of customers sits in each tier, and does tenure correlate with tier?

### LinkedIn post
> **Hook:** "One innocent-looking WHERE clause silently deleted rows from my result — and I didn't notice until I counted."
>
> Explain three-valued logic with the null truth table (photo of your handwritten version). This is a genuinely under-taught gotcha, so it teaches your audience something real. *Day 2 of 5.*

---

# Day 3 — Advanced Joins, Nested Queries & Operators

### Learn
**Why joins exist.** Relational databases deliberately split data across tables to avoid repetition (this is *normalization*) — customers in one table, their invoices in another, linked by a shared key (`CustomerId`). A **join** stitches those tables back together at query time by matching rows on a condition you specify in the **`ON`** clause. Where `WHERE` picks rows *within* a table, a join combines rows *across* tables, side by side.

**The join types** (all differ only in how they treat rows that *don't* find a match):

- **`INNER JOIN`** — keeps only rows that match on both sides. A customer with no invoices, or an invoice with no matching customer, simply disappears. This is the default and the most common.
- **`LEFT JOIN`** (left outer) — keeps *every* row from the left table; where the right table has no match, its columns come back as NULL. Use this when the left table is your "spine" and you don't want to lose rows just because the other side is empty.
- **`RIGHT JOIN`** — the mirror image (every right row kept). Rare in practice; people just flip the table order and use `LEFT`.
- **`FULL OUTER JOIN`** — keeps everything from both sides, padding with NULL wherever either side lacks a match.
- **`CROSS JOIN`** — every row of A paired with every row of B (the Cartesian product). Occasionally useful for generating combinations; usually a sign of a forgotten `ON` if it appears by accident.
- **Self-join** — a table joined *to itself* using two aliases, so you can relate rows within one table. This is how you attach each employee to their manager (both live in `Employee`).
- **Multi-table joins** — chain several joins (`A JOIN B ON ... JOIN C ON ...`) to walk a path across three or more tables.

**The anti-join** is a pattern, not a keyword: *find rows in A that have no match in B*. You `LEFT JOIN` A to B and then keep only the rows where B's key `IS NULL` (or use `NOT EXISTS`). This is how you answer "which customers never ordered?" or "which products were never sold?"

**Set operators** stack result sets *vertically* (a join is horizontal). Both sides must have the same columns. **`UNION`** combines and removes duplicates; **`UNION ALL`** combines and keeps duplicates (faster — use it when you know there are none); **`INTERSECT`** returns rows common to both; **`EXCEPT`** returns rows in the first that aren't in the second.

**Subqueries** are queries nested inside another query:

- A **scalar subquery** returns a single value and can sit anywhere a value is expected (e.g. compare each row to the overall average).
- A subquery in **`WHERE`** with **`IN`** or **`EXISTS`** filters the outer query by a set produced elsewhere. `IN` checks membership in the returned list; `EXISTS` checks only *whether any* matching row exists (often faster, and null-safe).
- A **correlated subquery** references a column from the outer query, so it must re-run *once per outer row*. Picture it as a loop: for each outer row, run the inner query using that row's values. Powerful for per-group comparisons ("customers who beat their own country's average"), but understand it's doing real work per row.
- A subquery in **`FROM`** is a **derived table** — you query a query, treating its result as a temporary table. (On Day 5, CTEs give this same idea a cleaner name.)

**Two mental models to hold onto:** a join is *row-matching between sets* (draw both tables and line up the matches); a correlated subquery is *a loop that runs per outer row*.

**Translating from what you know:**

| pandas | SQL |
|---|---|
| `pd.merge(a, b, how='inner', on='id')` | `a INNER JOIN b ON a.id = b.id` |
| `pd.merge(a, b, how='left', on='id')` | `a LEFT JOIN b ON a.id = b.id` |
| `pd.merge(a, b, how='outer', on='id')` | `a FULL OUTER JOIN b ON a.id = b.id` |
| `pd.concat([a, b])` | `a UNION ALL b` |
| `a[~a.id.isin(b.id)]` (anti-join) | `LEFT JOIN ... WHERE b.id IS NULL` |
| merge a frame with itself | self-join with two aliases |

### Pen & paper
Draw two small tables — `customers` and `invoices` — where one customer has no invoices and one invoice has an orphaned reference. By hand, produce the exact output rows for:
- `INNER JOIN` (only matches)
- `LEFT JOIN` (all customers, nulls where no invoice)
- `FULL OUTER JOIN` (everything, nulls on both sides)
- the **anti-join** (customers with zero invoices)

Then trace a **correlated subquery** — e.g. "customers who spent more than their country's average" — writing out the inner query's result for each outer row.

### Case study → `day3-joins-and-hierarchy/`
**Business question:** *"Build a sales-rep performance view: which support reps drive the most revenue, who reports to whom, and which customers have never purchased?"*

Deliverables:
- Multi-table join: `employees` → `customers` → `invoices` for revenue per rep.
- **Self-join** on `employees` to attach each rep's manager.
- **Anti-join** to list customers with no invoices.
- A correlated subquery for reps performing above the team average.
- Insight: the sales leaderboard and any manager-level patterns.

### LinkedIn post
> **Hook:** "INNER vs LEFT vs FULL JOIN — explained on 4 rows you can draw by hand. If you can draw the output, you understand joins."
>
> Photo of your four hand-drawn join outputs side by side. Optional second post later in the week on the *anti-join* ("how to find what isn't there"), which surprises people. *Day 3 of 5.*

---

# Day 4 — Window Functions

### Learn
**The mental model that unlocks everything: a window function aggregates *without collapsing your rows.*** `GROUP BY` turns 1,000 rows into 10 summary rows. A window function keeps all 1,000 rows and *adds* a new column computed over a "window" of related rows. That's the whole idea — same row count in, same row count out, plus a column that "sees" its neighbours.

Every window function is written as `function() OVER (window definition)`. The **`OVER()`** clause is what makes a function a window function, and it has three parts, all optional:

- **`PARTITION BY`** — divides the rows into groups *for this calculation only*. It's "group, but don't collapse." `PARTITION BY genre` means the function restarts for each genre. Omit it and the whole result is one partition.
- **`ORDER BY`** (inside `OVER`) — orders the rows *within* each partition. It's required for anything sequential — running totals, rankings, previous/next-row lookups — because "running" and "previous" only mean something once rows have an order.
- **The frame clause** (`ROWS BETWEEN ... AND ...`) — defines *which rows around the current row* are in scope. `ROWS BETWEEN 2 PRECEDING AND CURRENT ROW` is a 3-row trailing window (a moving average); `ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW` is everything up to here (a running total).

**The function families:**

- **Ranking** — **`ROW_NUMBER()`** gives every row a unique sequential number (ties broken arbitrarily). **`RANK()`** gives tied rows the same rank and then *skips* (1, 2, 2, 4). **`DENSE_RANK()`** gives ties the same rank but *doesn't skip* (1, 2, 2, 3). **`NTILE(n)`** splits rows into `n` roughly equal buckets (quartiles, deciles). The differences only show up on ties — which is exactly why you compute them side by side.
- **Offset** — **`LAG(col)`** returns the value from the *previous* row, **`LEAD(col)`** from the *next* row. This is how you compute period-over-period change without a self-join: `revenue - LAG(revenue)`. The first row's `LAG` is NULL (there's nothing before it).
- **Aggregate windows** — `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` used *with* `OVER()`. `SUM(x) OVER (ORDER BY month)` is a running total; `AVG(x) OVER (... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` is a moving average.
- **Positional** — **`FIRST_VALUE`** / **`LAST_VALUE`** return the first/last value in the frame (e.g. first purchase in each customer's history).

One gotcha worth knowing now: when you add `ORDER BY` inside `OVER` but *don't* specify a frame, most databases default to a running frame (`RANGE ... UNBOUNDED PRECEDING TO CURRENT ROW`), not the whole partition. If a windowed `SUM` surprises you, name the frame explicitly.

This is often the single highest-value SQL skill for an analyst, and it's the concept pen-and-paper helps most.

**Translating from what you know:**

| pandas | SQL window |
|---|---|
| `df.groupby('g').x.transform('sum')` | `SUM(x) OVER (PARTITION BY g)` |
| `df.x.cumsum()` | `SUM(x) OVER (ORDER BY ...)` |
| `df.x.rolling(3).mean()` | `AVG(x) OVER (... ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` |
| `df.x.shift(1)` | `LAG(x) OVER (ORDER BY ...)` |
| `df.groupby('g').x.rank(method='first')` | `ROW_NUMBER() OVER (PARTITION BY g ORDER BY x)` |
| `pd.qcut(df.x, 4)` | `NTILE(4) OVER (ORDER BY x)` |

### Pen & paper
Draw an 8-row monthly-sales table (month, revenue). By hand, compute three new columns:
1. **Running total** — walk down the rows, accumulating.
2. **3-month moving average** — draw the frame (current row + 2 prior) around each row and average within it.
3. **`ROW_NUMBER` vs `RANK` vs `DENSE_RANK`** — introduce a tie in the data and hand-compute all three so you *feel* how they differ on ties.

Also hand-compute a **`LAG`** column (previous month's revenue) and then month-over-month change. When you've done this by hand, window functions stop being magic.

### Case study → `day4-window-functions/`
**Business question:** *"Analyze revenue over time and find the top tracks within each genre."*

Deliverables:
- Monthly revenue with a **running total** and **month-over-month change** (`LAG`).
- A **moving average** to smooth the trend.
- Top 3 tracks *per genre* using `ROW_NUMBER()`/`RANK()` with `PARTITION BY genre` (the classic "top-N-per-group" pattern).
- Insight: the revenue trend and which genres have the most concentrated hits.

### LinkedIn post
> **Hook:** "GROUP BY collapses your rows. Window functions don't. Here's the difference, drawn out row by row."
>
> Photo of your hand-computed running total + moving average + the three ranking functions on tied data. This is a genuinely useful "aha" for other analysts. *Day 4 of 5.*

---

# Day 5 — Advanced SQL with Common Table Expressions (CTEs)

### Learn
**What a CTE is.** A Common Table Expression, written with the **`WITH`** keyword, is a named temporary result set that exists only for the duration of one query. You define it once at the top — `WITH monthly AS ( ... )` — and then reference `monthly` in the main query as if it were a table. Nothing is stored; it's a naming device that lets you break a hard problem into readable, labelled steps.

**Why they matter:**

- **Readability and decomposition.** A query with three levels of nested subqueries reads inside-out and is miserable to debug. The same logic as chained CTEs reads top-to-bottom, like a pipeline: each `WITH` block is one clear step, and you can run each block on its own to check it. For an analyst, this is the difference between a query you can maintain and one you rewrite from scratch every time.
- **Chaining.** You can define several CTEs in one `WITH`, separated by commas, and each can reference the ones defined before it. That's how you build a multi-stage transformation — clean, then aggregate, then rank — with each stage named.
- **CTE vs subquery.** They have the *same* power; a CTE is mostly a subquery you've pulled out and given a name. Reach for a CTE when the logic is reused or when nesting would hurt readability. (One nuance: some databases *materialize* CTEs and some inline them, which can affect performance — worth knowing exists, not worth worrying about on Day 5.)

**Recursive CTEs.** A recursive CTE references *itself*, which lets SQL do something it otherwise can't: walk a structure of unknown depth — an org chart, a folder tree, a bill of materials, a chain of prerequisites. The shape is always the same and reads like mathematical induction:

- an **anchor member** (the base case — e.g. the employee at the top with no manager),
- **`UNION ALL`**,
- a **recursive member** that joins back to the CTE to find the next level (everyone who reports to someone already found),
- and it repeats until the recursive member produces no new rows (termination).

You can also use recursion to *generate* rows — a sequence of dates or numbers — when you have no table to draw them from.

**The payoff — combining CTEs with window functions.** Most real analytics patterns are a short pipeline of CTEs where a window function does the heavy lifting in one stage: **cohort/retention analysis** (assign a cohort, then measure activity over time), **funnels** (stage counts and drop-off), and **deduplication** (`ROW_NUMBER()` per group, then keep only `rn = 1` to grab one row per entity). This is where everything from the week comes together.

**Two mental models:** a CTE is *a named intermediate table for this one query*; a recursive CTE is *induction* — a base case plus a step that repeats until nothing new appears.

**Translating from what you know:** a CTE is the SQL version of assigning an intermediate DataFrame to a variable and building on it step by step — `monthly = df.groupby(...).sum()` then working from `monthly` — rather than writing one unreadable chained expression. A recursive CTE is the tree/graph traversal you'd normally write as a Python loop or recursion, expressed declaratively in SQL.

### Pen & paper
Two drills:

1. **Refactor by decomposition.** Take a deeply nested query from Day 3 or 4 and redraw it as **labeled boxes** — one box per CTE, arrows showing data flow. Then write the `WITH ... AS (...)` version from your boxes.
2. **Trace a recursive CTE.** On the `employees` hierarchy, hand-execute the recursion: write the anchor row (the top manager), then each recursion level (their reports, then reports-of-reports), tracking a `depth` counter, until the tree is exhausted.

### Case study → `day5-cte-analytics/`
**Business question:** *"Build a customer cohort/retention analysis, and produce a full employee org chart with reporting depth."*

Deliverables:
- **Cohort analysis:** a CTE assigning each customer to a cohort by first-purchase month, a second CTE computing activity by later month, combined with window functions into a retention view.
- **Recursive CTE:** the full `employees` org chart with each person's `depth` in the hierarchy.
- This is your portfolio centerpiece — it shows you can decompose a hard problem, not just write a clause.

### The capstone (this is your "real data" portfolio piece) → `capstone-realworld/`
Re-run your strongest case study on a **genuinely real, messy public dataset** to earn the real-data signal:

- **NYC Taxi trips** (huge, time-series — great for window functions and teaches you why query structure matters at scale).
- **Olympics history** or a **Kaggle e-commerce dataset** (rich joins, dates, categories).
- **data.gov**, **Google BigQuery public datasets** (free sandbox tier), or **Kaggle** for the download.

Pick one, load it, and reproduce a running-total / top-N / cohort analysis. Cleaning real data *is* the point — write up what was messy and how you handled it.

### LinkedIn post
> **Hook:** "I took a 5-level-deep nested query and refactored it into a readable CTE pipeline. Same result — but now a human can actually read it."
>
> Post the before/after (nested vs `WITH` boxes). A strong follow-up: *"How SQL walks a tree"* with your hand-traced recursive CTE. Close the series: *Day 5 of 5 — here's the full portfolio repo.* Link GitHub. *This is your highest-value post of the week — it's the one that shows range.*

---

## Assembling the portfolio (after Day 5)

- **Write the top-level `README.md`** as a short narrative: what you set out to learn, the five case studies (linked), the dataset, and the tools. Recruiters read this first.
- **Every case study README follows the same shape:** business question → approach → query → result screenshot → insight. Consistency reads as professionalism.
- **Pin the repo** on your GitHub profile and link it in your LinkedIn "Featured" section.
- **Turn the five daily posts into a series** — same visual template, "Day X of 5" tag, and a final wrap-up post linking the repo. The pen-and-paper photos are your differentiator; most people only post code.

## A note on dialects

You'll practice in SQLite (or Postgres). ~90% of what you learn is standard SQL and transfers everywhere. The main things that differ across databases are date functions, string concatenation syntax, and a few function names. When you hit a job posting naming a specific database (Postgres, Snowflake, BigQuery, SQL Server), you're adjusting details — not relearning.

---

*Built for learning in public: reason on paper, prove it in code, ship it to a portfolio, and narrate the journey.*
