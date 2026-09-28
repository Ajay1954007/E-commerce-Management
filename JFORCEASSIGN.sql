
DROP DATABASE IF EXISTS jforce_ecommerce;
CREATE DATABASE jforce_ecommerce;
USE jforce_ecommerce;

CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    city VARCHAR(80) NOT NULL,
    status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active'
) ENGINE=InnoDB;

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(120) NOT NULL,
    category VARCHAR(80) NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    status ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
    CONSTRAINT chk_product_price CHECK (price >= 0),
    CONSTRAINT chk_product_stock CHECK (stock_quantity >= 0)
) ENGINE=InnoDB;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status ENUM('Pending','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
    total_amount DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_order_total CHECK (total_amount >= 0),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    INDEX idx_orders_customer_date (customer_id, order_date),
    INDEX idx_orders_status_date (order_status, order_date)
) ENGINE=InnoDB AUTO_INCREMENT=5001;

CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(12,2) NOT NULL,
    CONSTRAINT chk_item_quantity CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price >= 0),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_items_product (product_id)
) ENGINE=InnoDB;

INSERT INTO customers VALUES
(101,'Ajay Yadav','ajay101@example.com','Karad','Active'),
(102,'Priya Patil','priya102@example.com','Pune','Active'),
(103,'Rahul Shah','rahul103@example.com','Mumbai','Active'),
(104,'Sneha Kulkarni','sneha104@example.com','Satara','Active'),
(105,'Amit Desai','amit105@example.com','Nashik','Active'),
(106,'Neha Joshi','neha106@example.com','Kolhapur','Active'),
(107,'Rohan More','rohan107@example.com','Sangli','Inactive'),
(108,'Pooja Pawar','pooja108@example.com','Nagpur','Active');


INSERT INTO products VALUES
(301,'Laptop','Electronics',45000.00,20,'Active'),
(302,'Wireless Mouse','Electronics',750.00,75,'Active'),
(303,'Keyboard','Electronics',1200.00,45,'Active'),
(304,'Monitor','Electronics',12500.00,18,'Active'),
(305,'USB-C Cable','Electronics',350.00,120,'Active'),
(306,'Headphones','Electronics',2200.00,40,'Active'),
(307,'Office Chair','Furniture',6800.00,15,'Active'),
(308,'Study Desk','Furniture',5200.00,12,'Active'),
(309,'Notebook','Stationery',90.00,200,'Active'),
(310,'Pen Set','Stationery',180.00,140,'Active'),
(311,'Water Bottle','Home',450.00,65,'Active'),
(312,'Backpack','Accessories',1500.00,30,'Active'),
(313,'Desk Lamp','Home',950.00,32,'Active'),
(314,'Smart Watch','Electronics',3200.00,22,'Active'),
(315,'Old Tablet','Electronics',8500.00,0,'Inactive');

INSERT INTO orders (order_id, customer_id, order_date, order_status, total_amount) VALUES
(5001,101,'2026-09-02','Pending',46500.00),
(5002,102,'2026-09-03','Completed',2950.00),
(5003,103,'2026-09-04','Completed',13450.00),
(5004,104,'2026-09-05','Pending',1150.00),
(5005,105,'2026-09-06','Completed',8300.00),
(5006,106,'2026-09-07','Cancelled',1800.00),
(5007,101,'2026-09-08','Completed',3200.00),
(5008,102,'2026-09-09','Completed',1100.00),
(5009,103,'2026-09-10','Pending',5700.00),
(5010,104,'2026-09-11','Completed',1260.00),
(5011,105,'2026-09-12','Completed',6700.00),
(5012,106,'2026-09-13','Completed',3400.00),
(5013,108,'2026-09-14','Pending',4700.00),
(5014,101,'2026-09-15','Completed',1850.00),
(5015,102,'2026-09-16','Completed',1560.00);


INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(5001,301,1,45000.00),(5001,302,2,750.00),
(5002,306,1,2200.00),(5002,302,1,750.00),
(5003,304,1,12500.00),(5003,313,1,950.00),
(5004,305,2,350.00),(5004,309,2,90.00),(5004,310,1,180.00),(5004,309,1,90.00),
(5005,307,1,6800.00),(5005,312,1,1500.00),
(5006,310,5,180.00),(5006,311,2,450.00),
(5007,314,1,3200.00),
(5008,302,1,750.00),(5008,305,1,350.00),
(5009,308,1,5200.00),(5009,305,1,350.00),(5009,309,1,90.00),(5009,310,1,60.00),
(5010,309,10,90.00),(5010,310,2,180.00),
(5011,308,1,5200.00),(5011,312,1,1500.00),
(5012,306,1,2200.00),(5012,303,1,1200.00),
(5013,314,1,3200.00),(5013,312,1,1500.00),
(5014,312,1,1500.00),(5014,305,1,350.00),
(5015,303,1,1200.00),(5015,310,2,180.00);


ALTER TABLE orders AUTO_INCREMENT = 5016;
