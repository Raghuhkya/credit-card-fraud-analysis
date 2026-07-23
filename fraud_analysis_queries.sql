SELECT * FROM transactions;


-- Rank transactions by risk score within each merchant category (window function)
SELECT transaction_id, merchant_category, amount, is_fraud,
       RANK() OVER (PARTITION BY merchant_category ORDER BY amount DESC) AS amount_rank
FROM transactions
WHERE is_fraud = 1;


-- CTE + subquery: categories with above-average fraud rate
WITH category_fraud AS (
    SELECT merchant_category,
           COUNT(*) AS total_txns,
           SUM(is_fraud) AS fraud_txns,
           SUM(is_fraud)/COUNT(*) AS fraud_rate
    FROM transactions
    GROUP BY merchant_category
)
SELECT * FROM category_fraud
WHERE fraud_rate > (SELECT AVG(fraud_rate) FROM category_fraud);


-- Case statement to bucket risk levels
SELECT transaction_id, amount, device_trust_score,
    CASE
        WHEN device_trust_score < 40 THEN 'High Risk'
        WHEN device_trust_score BETWEEN 40 AND 70 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_bucket
FROM transactions;



-- for join we'll add other table and then join it --
CREATE TABLE category_risk_notes (
    merchant_category VARCHAR(50) PRIMARY KEY,
    risk_level VARCHAR(20),
    recommended_action VARCHAR(100)
);

INSERT INTO category_risk_notes VALUES
('Grocery', 'High', 'Flag for manual review above ₹500'),
('Food', 'Medium', 'Monitor velocity patterns'),
('Travel', 'Medium', 'Verify foreign transactions'),
('Electronics', 'Low', 'Standard monitoring'),
('Clothing', 'Low', 'Standard monitoring');


-- join statments--
SELECT t.merchant_category, 
       COUNT(*) AS total_txns,
       SUM(t.is_fraud) AS fraud_txns,
       r.risk_level,
       r.recommended_action
FROM transactions t
JOIN category_risk_notes r 
ON t.merchant_category = r.merchant_category
GROUP BY t.merchant_category, r.risk_level, r.recommended_action
ORDER BY fraud_txns DESC;

