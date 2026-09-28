
USE jforce_ecommerce;
DROP PROCEDURE IF EXISTS SearchProducts;
DROP PROCEDURE IF EXISTS CheckStock;
DROP PROCEDURE IF EXISTS PlaceOrder;
DROP PROCEDURE IF EXISTS CancelOrder;
DROP PROCEDURE IF EXISTS GetCustomerOrderHistory;
DROP PROCEDURE IF EXISTS GetSalesReport;
DROP PROCEDURE IF EXISTS GetTopSellingProducts;
DELIMITER $$

CREATE PROCEDURE SearchProducts(IN p_category VARCHAR(80), IN p_max_price DECIMAL(12,2))
BEGIN
    IF p_max_price IS NULL OR p_max_price < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Maximum price must be nonnegative';
    END IF;
    SELECT product_id, product_name, category, price, stock_quantity
    FROM products
    WHERE status = 'Active'
      AND (p_category IS NULL OR TRIM(p_category) = '' OR category = p_category)
      AND price <= p_max_price
    ORDER BY price ASC, product_id ASC;
END$$

CREATE PROCEDURE CheckStock(IN p_product_id INT, IN p_requested_quantity INT)
BEGIN
    DECLARE v_name VARCHAR(120);
    DECLARE v_stock INT;
    DECLARE v_status VARCHAR(10);
    IF p_requested_quantity IS NULL OR p_requested_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Requested quantity must be positive';
    END IF;
    SELECT product_name, stock_quantity, status INTO v_name, v_stock, v_status
    FROM products WHERE product_id = p_product_id;
    IF v_name IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    END IF;
    SELECT v_name AS product_name, v_stock AS available_stock,
           p_requested_quantity AS requested_quantity,
           CASE WHEN v_status = 'Inactive' THEN 'Insufficient'
                WHEN v_stock >= p_requested_quantity THEN 'Sufficient'
                ELSE 'Insufficient' END AS stock_status;
END$$

CREATE PROCEDURE PlaceOrder(IN p_customer_id INT, IN p_product_id INT, IN p_quantity INT)
BEGIN
    DECLARE v_customer_status VARCHAR(10);
    DECLARE v_product_status VARCHAR(10);
    DECLARE v_price DECIMAL(12,2);
    DECLARE v_stock INT;
    DECLARE v_total DECIMAL(12,2);
    DECLARE v_order_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    IF p_quantity IS NULL OR p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be positive';
    END IF;
    START TRANSACTION;
    SET v_customer_status = NULL;
    SELECT status INTO v_customer_status FROM customers
    WHERE customer_id = p_customer_id FOR UPDATE;
    IF v_customer_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    ELSEIF v_customer_status <> 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer is inactive';
    END IF;
    SET v_product_status = NULL;
    SELECT price, stock_quantity, status INTO v_price, v_stock, v_product_status
    FROM products WHERE product_id = p_product_id FOR UPDATE;
    IF v_product_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
    ELSEIF v_product_status <> 'Active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product is inactive';
    ELSEIF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient stock';
    END IF;
    SET v_total = v_price * p_quantity;
    INSERT INTO orders (customer_id, order_date, order_status, total_amount)
    VALUES (p_customer_id, CURRENT_DATE(), 'Pending', v_total);
    SET v_order_id = LAST_INSERT_ID();
    INSERT INTO order_items (order_id, product_id, quantity, unit_price)
    VALUES (v_order_id, p_product_id, p_quantity, v_price);
    UPDATE products SET stock_quantity = stock_quantity - p_quantity
    WHERE product_id = p_product_id AND stock_quantity >= p_quantity;
    IF ROW_COUNT() <> 1 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inventory update failed';
    END IF;
    COMMIT;
    SELECT v_order_id AS order_id, v_total AS total_amount, 'Pending' AS order_status;
END$$

CREATE PROCEDURE CancelOrder(IN p_order_id INT)
BEGIN
    DECLARE v_status VARCHAR(12);
    DECLARE v_restored INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    SET v_status = NULL;
    SELECT order_status INTO v_status FROM orders
    WHERE order_id = p_order_id FOR UPDATE;
    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order not found';
    ELSEIF v_status <> 'Pending' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only pending orders can be cancelled';
    END IF;
    -- Lock affected product rows in consistent product_id order to reduce deadlock risk.
    -- This procedure restores every item, including repeated products in an order.
    SELECT COALESCE(SUM(quantity), 0) INTO v_restored
    FROM order_items WHERE order_id = p_order_id;
    UPDATE products p
    JOIN (SELECT product_id, SUM(quantity) AS qty FROM order_items
          WHERE order_id = p_order_id GROUP BY product_id) x
      ON x.product_id = p.product_id
    SET p.stock_quantity = p.stock_quantity + x.qty;
    UPDATE orders SET order_status = 'Cancelled' WHERE order_id = p_order_id;
    COMMIT;
    SELECT p_order_id AS order_id, 'Cancelled' AS cancellation_status,
           v_restored AS restored_quantity;
END$$

CREATE PROCEDURE GetCustomerOrderHistory(IN p_customer_id INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer not found';
    END IF;
    SELECT c.customer_name, o.order_id, o.order_date,
           GROUP_CONCAT(CONCAT(p.product_name, ' (', oi.quantity, ')')
                        ORDER BY oi.order_item_id SEPARATOR ', ') AS products_and_quantities,
           SUM(oi.quantity) AS total_quantity,
           o.total_amount, o.order_status
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE c.customer_id = p_customer_id
    GROUP BY c.customer_id, c.customer_name, o.order_id, o.order_date,
             o.total_amount, o.order_status
    ORDER BY o.order_date DESC, o.order_id DESC;
END$$

CREATE PROCEDURE GetSalesReport(IN p_start_date DATE, IN p_end_date DATE)
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid date range';
    END IF;
    SELECT COUNT(*) AS order_count,
           COALESCE(SUM(item_totals.units), 0) AS units_sold,
           COALESCE(SUM(o.total_amount), 0.00) AS total_sales,
           COALESCE(ROUND(AVG(o.total_amount), 2), 0.00) AS average_order_value
    FROM orders o
    JOIN (SELECT order_id, SUM(quantity) AS units FROM order_items GROUP BY order_id)
         item_totals ON item_totals.order_id = o.order_id
    WHERE o.order_status = 'Completed'
      AND o.order_date BETWEEN p_start_date AND p_end_date;
END$$

CREATE PROCEDURE GetTopSellingProducts(IN p_start_date DATE, IN p_end_date DATE)
BEGIN
    IF p_start_date IS NULL OR p_end_date IS NULL OR p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid date range';
    END IF;
    SELECT p.product_id, p.product_name, p.category,
           SUM(oi.quantity) AS quantity_sold,
           SUM(oi.quantity * oi.unit_price) AS sales_amount
    FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    JOIN products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'Completed'
      AND o.order_date BETWEEN p_start_date AND p_end_date
    GROUP BY p.product_id, p.product_name, p.category
    ORDER BY quantity_sold DESC, sales_amount DESC, p.product_id ASC
    LIMIT 5;
END$$
DELIMITER ;
