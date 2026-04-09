-- 1. Total amount spent by each customer
SELECT 
    s.userid,
    SUM(p.price) AS total_amount
FROM sales s
JOIN product p 
    ON s.product_id = p.product_id
GROUP BY s.userid;



-- 2. Number of visits per user
SELECT 
    userid,
    COUNT(DISTINCT created_date) AS visit_count
FROM sales
GROUP BY userid;



-- 3. First product purchased by each user
WITH ranked_sales AS (
    SELECT 
        userid,
        product_id,
        created_date,
        RANK() OVER (PARTITION BY userid ORDER BY created_date) AS rnk
    FROM sales
)
SELECT *
FROM ranked_sales
WHERE rnk = 1;



-- 4. First item purchased after becoming a gold member
WITH gold_purchases AS (
    SELECT 
        s.userid,
        s.created_date,
        g.gold_signup_date,
        s.product_id,
        RANK() OVER (PARTITION BY s.userid ORDER BY s.created_date) AS rnk
    FROM sales s
    JOIN goldusers_signup g 
        ON s.userid = g.userid
    WHERE s.created_date >= g.gold_signup_date
)
SELECT *
FROM gold_purchases
WHERE rnk = 1;



-- 5. Last item purchased before becoming a gold member
WITH pre_gold_purchases AS (
    SELECT 
        s.userid,
        s.created_date,
        g.gold_signup_date,
        s.product_id,
        RANK() OVER (PARTITION BY s.userid ORDER BY s.created_date DESC) AS rnk
    FROM sales s
    JOIN goldusers_signup g 
        ON s.userid = g.userid
    WHERE s.created_date < g.gold_signup_date
)
SELECT *
FROM pre_gold_purchases
WHERE rnk = 1;



-- 6. Total number of items and total amount spent before becoming a member
WITH pre_gold_sales AS (
    SELECT 
        s.userid,
        s.product_id,
        p.price
    FROM sales s
    JOIN goldusers_signup g 
        ON s.userid = g.userid
    JOIN product p 
        ON s.product_id = p.product_id
    WHERE s.created_date < g.gold_signup_date
)
SELECT 
    userid,
    COUNT(product_id) AS total_items,
    SUM(price) AS total_amount
FROM pre_gold_sales
GROUP BY userid;



-- 7A. Total reward points earned by each user
WITH user_spending AS (
    SELECT 
        s.userid,
        s.product_id,
        SUM(p.price) AS total_price
    FROM sales s
    JOIN product p 
        ON s.product_id = p.product_id
    GROUP BY s.userid, s.product_id
),
points_calc AS (
    SELECT *,
        CASE 
            WHEN product_id = 1 THEN 5
            WHEN product_id = 2 THEN 2
            WHEN product_id = 3 THEN 5
        END AS points
    FROM user_spending
)
SELECT 
    userid,
    SUM(total_price / points) AS total_points
FROM points_calc
GROUP BY userid;



-- 7B. Total reward points per product
WITH product_spending AS (
    SELECT 
        s.product_id,
        SUM(p.price) AS total_price
    FROM sales s
    JOIN product p 
        ON s.product_id = p.product_id
    GROUP BY s.product_id
),
points_calc AS (
    SELECT *,
        CASE 
            WHEN product_id = 1 THEN 5
            WHEN product_id = 2 THEN 2
            WHEN product_id = 3 THEN 5
        END AS points
    FROM product_spending
)
SELECT 
    product_id,
    SUM(total_price / points) AS total_points
FROM points_calc
GROUP BY product_id;



-- 8. Rank all transactions (Gold members only, others marked as 'NA')
WITH ranked_transactions AS (
    SELECT 
        s.userid,
        s.created_date,
        g.gold_signup_date,
        s.product_id,
        CASE 
            WHEN g.gold_signup_date IS NOT NULL 
                 AND s.created_date >= g.gold_signup_date
            THEN RANK() OVER (PARTITION BY s.userid ORDER BY s.created_date DESC)
        END AS rnk
    FROM sales s
    LEFT JOIN goldusers_signup g 
        ON s.userid = g.userid
)
SELECT 
    *,
    COALESCE(CAST(rnk AS VARCHAR), 'NA') AS gold_rank
FROM ranked_transactions;
