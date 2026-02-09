-- =====================================================
-- DATABASE SETUP AND DATA GENERATION
-- Customer Behavior & Revenue Intelligence System
-- =====================================================

-- Creating table 'customers'
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    
    name VARCHAR(100) NOT NULL,
    
    gender VARCHAR(10)
        CHECK (gender IN ('Male', 'Female', 'Other')),
    
    age INT
        CHECK (age BETWEEN 18 AND 65),
    
    city VARCHAR(50) NOT NULL,
    
    signup_date DATE NOT NULL
);

-- Creating table 'products'
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    
    product_name VARCHAR(100) NOT NULL,
    
    category VARCHAR(50) NOT NULL,
    
    price NUMERIC(10,2)
        CHECK (price > 0)
);

-- Creating table 'orders'
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    
    customer_id INT NOT NULL,
    
    order_date DATE NOT NULL,
    
    payment_method VARCHAR(20)
        CHECK (payment_method IN ('UPI', 'Card', 'NetBanking', 'COD')),
    
    order_value NUMERIC(10,2)
        CHECK (order_value > 0),
    
    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

-- Creating table 'order_items'
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    
    quantity INT
        CHECK (quantity > 0),
    
    CONSTRAINT fk_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    
    CONSTRAINT fk_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- Creating table 'customer_activity'
CREATE TABLE customer_activity (
    activity_id SERIAL PRIMARY KEY,
    
    customer_id INT NOT NULL UNIQUE,
    
    last_login DATE NOT NULL,
    
    support_tickets INT
        CHECK (support_tickets >= 0),
    
    CONSTRAINT fk_activity_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

-- Creating indexes on frequently joined and filtered columns
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);


-- =====================================================
-- DATA INSERTION
-- =====================================================

-- Inserting data into table 'customers'
INSERT INTO customers (name, gender, age, city, signup_date)
SELECT
    (
        CASE 
            WHEN gender = 'Male' THEN
                (ARRAY[
                    'Aarav','Rohan','Rahul','Kabir','Arjun',
                    'Aditya','Kunal','Mohit','Siddharth',
                    'Aman','Vikas','Nikhil','Varun'
                ])[FLOOR(random()*13)+1]

            WHEN gender = 'Female' THEN
                (ARRAY[
                    'Aanshi','Riya','Ananya','Priya','Kritika',
                    'Sneha','Neha','Pooja','Isha',
                    'Kajal','Megha','Shreya','Nidhi'
                ])[FLOOR(random()*13)+1]

            ELSE 'Alex'
        END
        || ' ' ||
        (ARRAY[
            'Sharma','Verma','Gupta','Mehta','Singh',
            'Patel','Khanna','Malhotra','Iyer','Chatterjee'
        ])[FLOOR(random()*10)+1]
    ) AS name,

    gender,

    (18 + FLOOR(random() * 48))::INT AS age,

    (ARRAY[
        'Delhi','Mumbai','Bangalore','Pune',
        'Hyderabad','Chennai','Kolkata','Jaipur'
    ])[FLOOR(random()*8)+1] AS city,

    CURRENT_DATE - (FLOOR(random() * 730))::INT AS signup_date

FROM (
    SELECT
        gs,
        CASE 
            WHEN random() < 0.48 THEN 'Male'
            WHEN random() < 0.96 THEN 'Female'
            ELSE 'Other'
        END AS gender
    FROM generate_series(1,1000) gs
) t;

-- Inserting data into table 'products'
INSERT INTO products (product_name, category, price)
VALUES
-- Electronics
('iPhone 14', 'Electronics', 79999),
('Samsung Galaxy S22', 'Electronics', 69999),
('Dell Inspiron Laptop', 'Electronics', 58999),
('HP Pavilion Laptop', 'Electronics', 61999),
('Boat Wireless Earbuds', 'Electronics', 2499),
('Sony Headphones', 'Electronics', 8999),
('Apple Watch SE', 'Electronics', 29999),
('Bluetooth Speaker', 'Electronics', 3999),
('Power Bank 20000mAh', 'Electronics', 1799),
('USB-C Charger', 'Electronics', 1299),

-- Accessories
('Leather Wallet', 'Accessories', 999),
('Analog Wrist Watch', 'Accessories', 3499),
('Sunglasses', 'Accessories', 1999),
('Backpack', 'Accessories', 2499),
('Laptop Sleeve', 'Accessories', 1499),
('Travel Duffel Bag', 'Accessories', 2999),
('Wireless Mouse', 'Accessories', 899),
('Keyboard Combo', 'Accessories', 1599),
('Phone Stand', 'Accessories', 499),
('Smart Keychain', 'Accessories', 699),

-- Stationery
('Notebook Set', 'Stationery', 399),
('Ball Pen Pack', 'Stationery', 199),
('Highlighter Set', 'Stationery', 299),
('Desk Organizer', 'Stationery', 599),
('Sticky Notes', 'Stationery', 149),
('Planner Diary', 'Stationery', 499),
('Geometry Box', 'Stationery', 249),
('Whiteboard Marker', 'Stationery', 179),
('Office File Folder', 'Stationery', 349),
('Correction Tape', 'Stationery', 99),

-- Home
('Mixer Grinder', 'Home', 3499),
('Electric Kettle', 'Home', 1999),
('Air Fryer', 'Home', 7999),
('Water Purifier', 'Home', 10999),
('LED Table Lamp', 'Home', 1299),
('Vacuum Cleaner', 'Home', 5999),
('Induction Cooktop', 'Home', 4499),
('Non-Stick Cookware Set', 'Home', 2999),
('Wall Clock', 'Home', 999),
('Bedsheet Set', 'Home', 1799);

-- Inserting data into table 'orders'
INSERT INTO orders (customer_id, order_date, payment_method, order_value)
SELECT
    FLOOR(random()*1000 + 1)::INT,
    CURRENT_DATE - (FLOOR(random()*365))::INT,
    (ARRAY[
        'UPI','Card','NetBanking','COD'
    ])[FLOOR(random()*4)+1],
    ROUND((500 + random()*20000)::numeric, 2)
FROM generate_series(1,8000);

-- Inserting data into table 'order_items'
INSERT INTO order_items (order_id, product_id, quantity)
SELECT
    o.order_id,
    p.product_id,
    FLOOR(random()*3 + 1)::INT AS quantity
FROM orders o
CROSS JOIN LATERAL (
    SELECT product_id
    FROM products
    ORDER BY random()
    LIMIT (1 + FLOOR(random()*2))::INT  -- Each order gets 1-3 random products
) p;

-- Inserting data into table 'customer_activity'
INSERT INTO customer_activity (customer_id, last_login, support_tickets)
SELECT
    customer_id,
    CURRENT_DATE - (FLOOR(random()*120))::INT,
    FLOOR(random()*6)::INT
FROM customers;


-- =====================================================
-- ML FEATURES TABLE
-- =====================================================

-- Creating ML features table for machine learning pipeline
CREATE TABLE customer_ml_features AS
WITH order_agg AS (
    SELECT
        customer_id,
        SUM(order_value) AS total_spent,
        AVG(order_value) AS avg_order_value,
        MAX(order_date) AS last_order_date,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
),
activity_agg AS (
    SELECT
        customer_id,
        last_login,
        support_tickets
    FROM customer_activity
)
SELECT
    c.customer_id,
    c.age,
    c.gender,
    c.city,
    COALESCE(o.total_orders, 0) AS total_orders,
    COALESCE(o.total_spent, 0) AS total_spent,
    COALESCE(o.avg_order_value, 0) AS avg_order_value,
    COALESCE(o.last_order_date, c.signup_date) AS last_order_date,
    COALESCE((CURRENT_DATE - COALESCE(o.last_order_date, c.signup_date)), 0) AS days_since_last_order,
    CASE 
        WHEN COALESCE(o.last_order_date, c.signup_date) < CURRENT_DATE - INTERVAL '90 days' THEN 1
        ELSE 0
    END AS churn
FROM customers c
LEFT JOIN order_agg o ON c.customer_id = o.customer_id
LEFT JOIN activity_agg a ON c.customer_id = a.customer_id;

-- Add primary key to ML features table
ALTER TABLE customer_ml_features 
ADD PRIMARY KEY (customer_id);


-- =====================================================
-- PREDICTIONS TABLE (FOR ML MODEL OUTPUT)
-- =====================================================

-- Create table to store churn predictions from ML model
CREATE TABLE customer_churn_predictions (
    customer_id INT PRIMARY KEY,
    churn_prediction INT CHECK (churn_prediction IN (0, 1)),
    churn_probability NUMERIC(5,4),
    prediction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_pred_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
);

-- Create index for faster lookups
CREATE INDEX idx_churn_predictions ON customer_churn_predictions(churn_prediction);


-- =====================================================
-- MODEL METADATA TABLE (TRACK MODEL PERFORMANCE)
-- =====================================================

-- Create table to track model versions and performance metrics
CREATE TABLE model_metadata (
    model_id SERIAL PRIMARY KEY,
    model_name VARCHAR(50) NOT NULL,
    accuracy NUMERIC(5,4),
    precision_score NUMERIC(5,4),
    recall_score NUMERIC(5,4),
    f1_score NUMERIC(5,4),
    training_samples INT,
    test_samples INT,
    training_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    notes TEXT
);


-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify record counts
SELECT 'customers' AS table_name, COUNT(*) AS record_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'customer_activity', COUNT(*) FROM customer_activity
UNION ALL
SELECT 'customer_ml_features', COUNT(*) FROM customer_ml_features
ORDER BY table_name;

-- Sample test
SELECT customer_id, name, gender, city, age
FROM customers
LIMIT 10;

-- Verify ML features are properly generated
SELECT customer_id, age, gender, city, total_orders, total_spent, days_since_last_order, churn
FROM customer_ml_features
LIMIT 10;

-- Check for any data quality issues
SELECT 
    'Customers with no orders' AS check_name,
    COUNT(*) AS count
FROM customer_ml_features
WHERE total_orders = 0
UNION ALL
SELECT 
    'Customers marked as churned',
    COUNT(*)
FROM customer_ml_features
WHERE churn = 1
UNION ALL
SELECT 
    'Orders without items',
    COUNT(DISTINCT o.order_id)
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;
