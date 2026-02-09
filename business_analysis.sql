-- =====================================================
-- BUSINESS ANALYSIS QUERIES
-- Customer Behavior & Revenue Intelligence System
-- =====================================================

-- Run this file AFTER:
-- 1. database_setup.sql (creates tables and data)
-- 2. customer_churn_ml.ipynb (generates predictions)


-- =====================================================
-- QUERY 1: Top 10% Customers by Revenue
-- =====================================================
-- Identifies highest-value customers for VIP programs
-- Using PERCENT_RANK for accurate top 10% calculation

SELECT 
    customer_id,
    name,
    total_spent,
    total_orders,
    ROUND((total_spent / total_orders), 2) AS avg_order_value
FROM (
    SELECT
        c.customer_id,
        c.name,
        SUM(o.order_value) AS total_spent,
        COUNT(o.order_id) AS total_orders,
        PERCENT_RANK() OVER (ORDER BY SUM(o.order_value) DESC) AS pct_rank
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.name
) t
WHERE pct_rank <= 0.10
ORDER BY total_spent DESC;


-- =====================================================
-- QUERY 2: City-wise Revenue Analysis
-- =====================================================
-- Shows which cities generate maximum revenue
-- Includes revenue per customer for targeting efficiency

SELECT
    c.city,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.order_value), 2) AS total_revenue,
    ROUND(AVG(o.order_value), 2) AS avg_order_value,
    ROUND(SUM(o.order_value)/COUNT(DISTINCT c.customer_id), 2) AS revenue_per_customer,
    ROUND(COUNT(o.order_id)::NUMERIC/COUNT(DISTINCT c.customer_id), 2) AS orders_per_customer
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY total_revenue DESC;


-- =====================================================
-- QUERY 3: Inactive/Churn-Risk Customers
-- =====================================================
-- Customers with no activity in last 90 days
-- Includes customers who never placed orders

SELECT
    c.customer_id,
    c.name,
    c.city,
    c.gender,
    c.age,
    COALESCE(MAX(o.order_date), c.signup_date) AS last_order_date,
    CURRENT_DATE - COALESCE(MAX(o.order_date), c.signup_date) AS days_inactive,
    COALESCE(COUNT(o.order_id), 0) AS total_orders,
    COALESCE(SUM(o.order_value), 0) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city, c.gender, c.age, c.signup_date
HAVING CURRENT_DATE - COALESCE(MAX(o.order_date), c.signup_date) > 90
ORDER BY days_inactive DESC;


-- =====================================================
-- QUERY 4: Repeat vs One-Time Customers
-- =====================================================
-- Segmentation for retention strategy
-- Shows percentage distribution

WITH order_counts AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE 
        WHEN total_orders = 1 THEN 'One-time'
        WHEN total_orders BETWEEN 2 AND 5 THEN 'Occasional (2-5)'
        WHEN total_orders BETWEEN 6 AND 10 THEN 'Regular (6-10)'
        ELSE 'Loyal (10+)'
    END AS customer_segment,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    ROUND(AVG(total_orders), 2) AS avg_orders
FROM order_counts
GROUP BY customer_segment
ORDER BY MIN(total_orders);


-- =====================================================
-- QUERY 5: Monthly Revenue Trends
-- =====================================================
-- Shows revenue trends over time
-- Includes month-over-month growth

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        ROUND(SUM(order_value), 2) AS monthly_revenue,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY month
)
SELECT
    TO_CHAR(month, 'Mon YYYY') AS month_label,
    monthly_revenue,
    total_orders,
    ROUND(monthly_revenue / total_orders, 2) AS avg_order_value,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month)) / 
        LAG(monthly_revenue) OVER (ORDER BY month), 
        2
    ) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


-- =====================================================
-- QUERY 6: Top Products by Revenue
-- =====================================================
-- Identifies best-selling products
-- Includes both revenue and units sold

SELECT
    p.product_name,
    p.category,
    p.price AS unit_price,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.quantity * p.price) AS product_revenue,
    COUNT(DISTINCT oi.order_id) AS number_of_orders,
    ROUND(AVG(oi.quantity), 2) AS avg_quantity_per_order
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name, p.category, p.price
ORDER BY product_revenue DESC
LIMIT 15;


-- =====================================================
-- QUERY 7: Category Performance Analysis
-- =====================================================
-- Revenue breakdown by product category

SELECT
    p.category,
    COUNT(DISTINCT p.product_id) AS products_in_category,
    SUM(oi.quantity) AS total_units_sold,
    ROUND(SUM(oi.quantity * p.price), 2) AS category_revenue,
    ROUND(AVG(p.price), 2) AS avg_product_price,
    ROUND(SUM(oi.quantity * p.price) / SUM(oi.quantity), 2) AS avg_revenue_per_unit
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;


-- =====================================================
-- QUERY 8: Customer Lifetime Value (CLV)
-- =====================================================
-- Top customers by total spending
-- Includes recency and frequency metrics

SELECT
    c.customer_id,
    c.name,
    c.city,
    c.gender,
    c.age,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(o.order_value), 2) AS lifetime_value,
    ROUND(AVG(o.order_value), 2) AS avg_order_value,
    MAX(o.order_date) AS last_order_date,
    CURRENT_DATE - MAX(o.order_date) AS days_since_last_order,
    ROUND(
        SUM(o.order_value) / 
        NULLIF(EXTRACT(DAYS FROM (MAX(o.order_date) - MIN(o.order_date))), 0) * 30,
        2
    ) AS estimated_monthly_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city, c.gender, c.age
ORDER BY lifetime_value DESC
LIMIT 20;


-- =====================================================
-- QUERY 9: Customer Ranking by Revenue
-- =====================================================
-- Dense ranking to avoid gaps in rankings
-- Useful for leaderboards and incentive programs

SELECT
    c.customer_id,
    c.name,
    c.city,
    ROUND(SUM(o.order_value), 2) AS total_spent,
    COUNT(o.order_id) AS total_orders,
    DENSE_RANK() OVER (ORDER BY SUM(o.order_value) DESC) AS revenue_rank,
    NTILE(10) OVER (ORDER BY SUM(o.order_value) DESC) AS decile_group
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.city
ORDER BY revenue_rank
LIMIT 25;


-- =====================================================
-- QUERY 10: Payment Method Analysis
-- =====================================================
-- Shows payment preferences and their revenue contribution

SELECT
    payment_method,
    COUNT(order_id) AS total_orders,
    ROUND(SUM(order_value), 2) AS total_revenue,
    ROUND(AVG(order_value), 2) AS avg_order_value,
    ROUND(100.0 * COUNT(order_id) / SUM(COUNT(order_id)) OVER (), 2) AS pct_of_orders,
    ROUND(100.0 * SUM(order_value) / SUM(SUM(order_value)) OVER (), 2) AS pct_of_revenue
FROM orders
GROUP BY payment_method
ORDER BY total_revenue DESC;


-- =====================================================
-- QUERY 11: Customer Cohort Analysis
-- =====================================================
-- Groups customers by signup month to track retention

WITH cohort_data AS (
    SELECT
        c.customer_id,
        DATE_TRUNC('month', c.signup_date) AS cohort_month,
        DATE_TRUNC('month', o.order_date) AS order_month
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
)
SELECT
    TO_CHAR(cohort_month, 'Mon YYYY') AS cohort,
    COUNT(DISTINCT customer_id) AS cohort_size,
    COUNT(DISTINCT CASE WHEN order_month IS NOT NULL THEN customer_id END) AS active_customers,
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN order_month IS NOT NULL THEN customer_id END) / 
        COUNT(DISTINCT customer_id),
        2
    ) AS activation_rate_pct
FROM cohort_data
GROUP BY cohort_month
ORDER BY cohort_month DESC;


-- =====================================================
-- QUERY 12: Age & Gender Demographics Analysis
-- =====================================================
-- Customer segmentation by demographics

SELECT
    gender,
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+'
    END AS age_group,
    COUNT(DISTINCT c.customer_id) AS customer_count,
    ROUND(AVG(o.order_value), 2) AS avg_order_value,
    ROUND(SUM(o.order_value), 2) AS total_revenue,
    ROUND(COUNT(o.order_id)::NUMERIC / COUNT(DISTINCT c.customer_id), 2) AS avg_orders_per_customer
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY gender, age_group
ORDER BY gender, age_group;


-- =====================================================
-- ML MODEL PREDICTIONS ANALYSIS
-- =====================================================
-- These queries use the predictions generated by the ML model

-- =====================================================
-- QUERY 13: Churn Prediction Summary
-- =====================================================
-- Overview of ML model predictions

SELECT
    churn_prediction,
    CASE 
        WHEN churn_prediction = 1 THEN 'Likely to Churn'
        ELSE 'Active/Retained'
    END AS prediction_label,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customer_churn_predictions
GROUP BY churn_prediction
ORDER BY churn_prediction;


-- =====================================================
-- QUERY 14: High-Risk Customers (Detailed)
-- =====================================================
-- Customers predicted to churn with their profiles
-- This is your target list for retention campaigns

SELECT
    c.customer_id,
    c.name,
    c.city,
    c.gender,
    c.age,
    f.total_orders,
    ROUND(f.total_spent, 2) AS total_spent,
    ROUND(f.avg_order_value, 2) AS avg_order_value,
    f.days_since_last_order,
    p.churn_probability,
    p.prediction_date,
    CASE 
        WHEN p.churn_probability >= 0.80 THEN 'Critical Risk'
        WHEN p.churn_probability >= 0.60 THEN 'High Risk'
        ELSE 'Medium Risk'
    END AS risk_level
FROM customers c
JOIN customer_ml_features f ON c.customer_id = f.customer_id
JOIN customer_churn_predictions p ON c.customer_id = p.customer_id
WHERE p.churn_prediction = 1
ORDER BY p.churn_probability DESC, f.total_spent DESC;


-- =====================================================
-- QUERY 15: Churn Risk by City
-- =====================================================
-- Geographical analysis of churn predictions

SELECT
    c.city,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN p.churn_prediction = 1 THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(
        100.0 * SUM(CASE WHEN p.churn_prediction = 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_pct,
    ROUND(AVG(CASE WHEN p.churn_prediction = 1 THEN f.total_spent ELSE NULL END), 2) AS avg_value_at_risk
FROM customers c
JOIN customer_ml_features f ON c.customer_id = f.customer_id
JOIN customer_churn_predictions p ON c.customer_id = p.customer_id
GROUP BY c.city
ORDER BY churn_rate_pct DESC;


-- =====================================================
-- QUERY 16: Model Validation
-- =====================================================
-- Compare ML predictions with actual churn labels

SELECT
    f.churn AS actual_churn,
    p.churn_prediction AS predicted_churn,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM customer_ml_features f
JOIN customer_churn_predictions p ON f.customer_id = p.customer_id
GROUP BY f.churn, p.churn_prediction
ORDER BY f.churn, p.churn_prediction;


-- =====================================================
-- QUERY 17: Revenue at Risk from Churn
-- =====================================================
-- Financial impact of predicted churn

SELECT
    'Total Revenue' AS metric,
    ROUND(SUM(f.total_spent), 2) AS amount
FROM customer_ml_features f
UNION ALL
SELECT
    'Revenue from Churning Customers',
    ROUND(SUM(f.total_spent), 2)
FROM customer_ml_features f
JOIN customer_churn_predictions p ON f.customer_id = p.customer_id
WHERE p.churn_prediction = 1
UNION ALL
SELECT
    'Percentage at Risk',
    ROUND(
        100.0 * SUM(CASE WHEN p.churn_prediction = 1 THEN f.total_spent ELSE 0 END) / 
        SUM(f.total_spent),
        2
    )
FROM customer_ml_features f
JOIN customer_churn_predictions p ON f.customer_id = p.customer_id;


-- =====================================================
-- QUERY 18: Retention Campaign Priority List
-- =====================================================
-- High-value customers at risk of churning
-- Sorted by potential revenue loss

SELECT
    c.customer_id,
    c.name,
    c.city,
    c.gender,
    ROUND(f.total_spent, 2) AS lifetime_value,
    f.total_orders,
    f.days_since_last_order,
    ROUND(p.churn_probability * 100, 2) AS churn_risk_pct,
    CASE 
        WHEN f.total_spent > 50000 AND p.churn_probability > 0.7 THEN 'Priority 1 - Immediate Action'
        WHEN f.total_spent > 30000 AND p.churn_probability > 0.6 THEN 'Priority 2 - High Attention'
        WHEN f.total_spent > 10000 AND p.churn_probability > 0.5 THEN 'Priority 3 - Standard Follow-up'
        ELSE 'Priority 4 - Monitor'
    END AS campaign_priority
FROM customers c
JOIN customer_ml_features f ON c.customer_id = f.customer_id
JOIN customer_churn_predictions p ON c.customer_id = p.customer_id
WHERE p.churn_prediction = 1
ORDER BY f.total_spent DESC, p.churn_probability DESC
LIMIT 50;