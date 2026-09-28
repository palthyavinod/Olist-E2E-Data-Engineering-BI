USE Olist_DB;

-- ================================================================
-- PHASE 2: DATABASE ARCHITECTURE & TRANSFORMATIONS
-- Full rebuild: staging tables + primary keys + foreign keys
-- Safe to run from scratch (drops and recreates everything)
-- ================================================================

-- ----------------------------------------------------------------
-- STEP 0: DROP EXISTING TABLES (in FK-safe order)
-- ----------------------------------------------------------------
DROP TABLE IF EXISTS stg_order_items;
DROP TABLE IF EXISTS stg_orders;
DROP TABLE IF EXISTS stg_products;
DROP TABLE IF EXISTS stg_sellers;
DROP TABLE IF EXISTS stg_customers;
DROP TABLE IF EXISTS stg_geolocation;

-- ----------------------------------------------------------------
-- STEP 1: CREATE + LOAD STAGING TABLES
-- ----------------------------------------------------------------

-- CUSTOMERS
CREATE TABLE stg_customers (
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(20),
    customer_city VARCHAR(100),
    customer_state VARCHAR(10)
);
BULK INSERT stg_customers
FROM 'C:\OlistData\olist_customers_dataset.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

-- PRODUCTS
CREATE TABLE stg_products (
    product_id VARCHAR(50),
    product_category_name VARCHAR(100),
    product_name_lenght VARCHAR(20),
    product_description_lenght VARCHAR(20),
    product_photos_qty VARCHAR(20),
    product_weight_g VARCHAR(20),
    product_length_cm VARCHAR(20),
    product_height_cm VARCHAR(20),
    product_width_cm VARCHAR(20)
);
BULK INSERT stg_products
FROM 'C:\OlistData\olist_products_dataset.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

-- SELLERS
CREATE TABLE stg_sellers (
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(20),
    seller_city VARCHAR(100),
    seller_state VARCHAR(10)
);
BULK INSERT stg_sellers
FROM 'C:\OlistData\olist_sellers_dataset.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

-- ORDERS
CREATE TABLE stg_orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(50),
    order_purchase_timestamp VARCHAR(50),
    order_approved_at VARCHAR(50),
    order_delivered_carrier_date VARCHAR(50),
    order_delivered_customer_date VARCHAR(50),
    order_estimated_delivery_date VARCHAR(50)
);
BULK INSERT stg_orders
FROM 'C:\OlistData\olist_orders_dataset.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

-- ORDER ITEMS
CREATE TABLE stg_order_items (
    order_id VARCHAR(50),
    order_item_id VARCHAR(10),
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date VARCHAR(50),
    price VARCHAR(20),
    freight_value VARCHAR(20)
);
BULK INSERT stg_order_items
FROM 'C:\OlistData\olist_order_items_dataset.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

-- GEOLOCATION
CREATE TABLE stg_geolocation (
    geolocation_zip_code_prefix VARCHAR(20),
    geolocation_lat VARCHAR(30),
    geolocation_lng VARCHAR(30),
    geolocation_city VARCHAR(100),
    geolocation_state VARCHAR(10)
);
BULK INSERT stg_geolocation
FROM 'C:\OlistData\olist_geolocation_dataset.csv'
WITH (FORMAT='CSV', FIRSTROW=2, FIELDQUOTE='"', FIELDTERMINATOR=',', ROWTERMINATOR='0x0a', CODEPAGE='65001', TABLOCK);

GO

-- ----------------------------------------------------------------
-- STEP 2: PRIMARY KEYS
-- (separate batch so column changes commit before constraints run)
-- ----------------------------------------------------------------
ALTER TABLE stg_customers ALTER COLUMN customer_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_products ALTER COLUMN product_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_sellers ALTER COLUMN seller_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_orders ALTER COLUMN order_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_order_items ALTER COLUMN order_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_order_items ALTER COLUMN order_item_id VARCHAR(10) NOT NULL;

GO

ALTER TABLE stg_customers ADD CONSTRAINT PK_customers PRIMARY KEY (customer_id);
ALTER TABLE stg_products ADD CONSTRAINT PK_products PRIMARY KEY (product_id);
ALTER TABLE stg_sellers ADD CONSTRAINT PK_sellers PRIMARY KEY (seller_id);
ALTER TABLE stg_orders ADD CONSTRAINT PK_orders PRIMARY KEY (order_id);
ALTER TABLE stg_order_items ADD CONSTRAINT PK_order_items PRIMARY KEY (order_id, order_item_id);

GO

-- ----------------------------------------------------------------
-- STEP 3: FOREIGN KEYS
-- ----------------------------------------------------------------
ALTER TABLE stg_orders ALTER COLUMN customer_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_order_items ALTER COLUMN product_id VARCHAR(50) NOT NULL;
ALTER TABLE stg_order_items ALTER COLUMN seller_id VARCHAR(50) NOT NULL;

GO

ALTER TABLE stg_orders ADD CONSTRAINT FK_orders_customers
    FOREIGN KEY (customer_id) REFERENCES stg_customers(customer_id);

ALTER TABLE stg_order_items ADD CONSTRAINT FK_items_orders
    FOREIGN KEY (order_id) REFERENCES stg_orders(order_id);

ALTER TABLE stg_order_items ADD CONSTRAINT FK_items_products
    FOREIGN KEY (product_id) REFERENCES stg_products(product_id);

ALTER TABLE stg_order_items ADD CONSTRAINT FK_items_sellers
    FOREIGN KEY (seller_id) REFERENCES stg_sellers(seller_id);

GO

-- ----------------------------------------------------------------
-- VERIFICATION
-- ----------------------------------------------------------------
SELECT 'stg_customers' AS tbls, COUNT(*) AS row_count FROM stg_customers
UNION ALL SELECT 'stg_products', COUNT(*) FROM stg_products
UNION ALL SELECT 'stg_sellers', COUNT(*) FROM stg_sellers
UNION ALL SELECT 'stg_orders', COUNT(*) FROM stg_orders
UNION ALL SELECT 'stg_order_items', COUNT(*) FROM stg_order_items
UNION ALL SELECT 'stg_geolocation', COUNT(*) FROM stg_geolocation;

SELECT 'Phase 2 completed successfully' AS status;