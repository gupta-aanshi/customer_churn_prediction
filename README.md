# Customer Churn Prediction - SQL + ML Integration Project:

A learning project exploring how to integrate machine learning predictions with SQL databases. Built this to understand the complete workflow from database → ML model → predictions back to database.

## What This Does?

This project connects SQL and Python/ML in a real workflow:

1. **PostgreSQL creates an e-commerce database** with customers, orders, and products (all synthetic data)
2. **Python trains an ML model** to predict which customers will churn
3. **Predictions get saved back to the database** 
4. **SQL queries use those predictions** for business analysis

The main goal was learning how these pieces integrate, not building a perfect ML model.

## Why I Built This?

I wanted to understand:
- How to properly connect Python and SQL (not just read, but write back too!)
- How ML predictions fit into a real data pipeline
- SQL window functions and advanced queries
- Feature engineering directly in SQL
- The full workflow from data → model → insights

## Project Files:

```
├── database_setup.sql           # Creates tables, generates sample data
├── customer_churn_ml.ipynb      # ML model training & prediction
├── business_analysis.sql        # 18 queries using the predictions
└── README.md                    # You're here!
```

## Data:

**Important: All data is synthetic/fake!** 

The `database_setup.sql` script automatically generates:
- **1,000 customers** with random names, ages (18-65), gender, cities
- **40 products** across 4 categories (Electronics, Accessories, Stationery, Home)
- **~8,000 orders** with random dates, payment methods, values
- **Order items** linking orders to products

**Why synthetic?** Easier to share publicly, no privacy issues, and I can control the patterns. The churn logic is simple: customers with no orders in 90+ days = churned.

**Data Characteristics:**
- Cities: Delhi, Mumbai, Bangalore, Pune, Hyderabad, Chennai, Kolkata, Jaipur
- Date range: Last 2 years of transactions
- Payment methods: UPI, Card, NetBanking, COD
- Churn rate: ~5% (realistic for e-commerce)

If you want to use your own data, just modify the `customer_ml_features` table structure to match your schema.

## Tech Stack:

- **PostgreSQL** - Database (first time setting up from scratch!)
- **Python** - pandas, scikit-learn, SQLAlchemy, psycopg2
- **Jupyter Notebook** - Interactive development
- **Logistic Regression** - Simple enough to understand while learning

## Quick Start:

### 1. Setup Database
```bash
# Create database
createdb customer_behavior_and_revenue_intelligence_system

# Run setup script (creates tables + data)
psql -d customer_behavior_and_revenue_intelligence_system -f database_setup.sql
```

### 2. Train Model & Generate Predictions
```bash
# Open notebook
jupyter notebook customer_churn_ml.ipynb

# Update database password in cell 3, then run all cells
```

The notebook will:
- Load data from PostgreSQL
- Train Logistic Regression model
- Save predictions back to database
- Export model as .pkl file

### 3. Run Business Analysis
```bash
# Run all queries
psql -d customer_behavior_and_revenue_intelligence_system -f business_analysis.sql

# Or run individual queries in your SQL client
```

## Key Learning Moments:

**Python-SQL Integration:**
- Figured out SQLAlchemy vs psycopg2 (when to use each)
- `pd.read_sql()` for reading, `to_sql()` for writing predictions back
- Handling data type conversions between SQL and pandas

**SQL Challenges:**
- Window functions (PERCENT_RANK, NTILE) - powerful but confusing!
- Feature engineering in SQL using CTEs and aggregations
- COALESCE for handling NULL values when customers have no orders

**ML Integration:**
- Getting predictions from notebook into a usable database table
- Creating a workflow where SQL queries can JOIN with ML predictions
- Realizing 99% accuracy doesn't mean much with synthetic data 😅

## Sample Queries You Can Run:

Once everything's set up, try these:

```sql
-- High-risk customers (predicted to churn)
SELECT * FROM customer_churn_predictions WHERE churn_prediction = 1;

-- Revenue at risk from churn
SELECT SUM(total_spent) FROM customer_ml_features f
JOIN customer_churn_predictions p ON f.customer_id = p.customer_id
WHERE p.churn_prediction = 1;

-- Churn rate by city
SELECT city, 
       COUNT(*) as customers,
       AVG(churn_prediction) as churn_rate
FROM customers c
JOIN customer_churn_predictions p USING(customer_id)
GROUP BY city;
```

See `business_analysis.sql` for more queries!

## Project Structure:

**Database Schema:**
- `customers` - Customer profiles
- `products` - Product catalog  
- `orders` - Transaction records
- `order_items` - Order line items
- `customer_ml_features` - Features for ML (auto-generated)
- `customer_churn_predictions` - Model output (populated by notebook)
- `model_metadata` - Tracks model performance

**ML Pipeline:**
- Features: age, gender, city, total_orders, total_spent, days_since_last_order
- Model: Logistic Regression (simple, interpretable)
- Accuracy: ~99% (but data is synthetic and pattern is obvious)

## Known Issues:

Being honest about what needs work:
- Database password hardcoded in notebook (need to use environment variables)
- Limited error handling - crashes aren't user-friendly
- Should add cross-validation
- Code in notebook could be cleaner (some cells do too much)
- Only tried one ML model - should compare others

## What's Next?

If I keep working on this:
- Add a simple Flask/Streamlit dashboard
- Try Random Forest and compare performance
- Add real-time prediction endpoint
- Better feature engineering (seasonality, product preferences)
- Learn about actual ML deployment

## Resources That Helped:

- PostgreSQL docs (dry but complete)
- Scikit-learn tutorials
- SQLAlchemy connection guides on YouTube
- Stack Overflow for debugging
- Trial and error (broke it many times!)

---

**Note:** This is a learning project, not production code! Built it to understand how SQL and ML connect in a real workflow. The data is fake, the code has rough edges, but that's part of learning. If you're also exploring this stuff, hope it helps! 🚀

Questions or found a bug? Feel free to reach out - still learning here!
