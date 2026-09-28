USE jforce_ecommerce;

SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;
CALL SearchProducts('Electronics', 50000);
CALL SearchProducts(NULL, 1000);
CALL CheckStock(301, 3);
SELECT product_id, stock_quantity FROM products WHERE product_id = 301;
CALL PlaceOrder(101, 301, 2);

SELECT product_id, stock_quantity FROM products WHERE product_id = 301;
CALL CancelOrder(5016); -- replace 5016 if your generated order ID differs
SELECT product_id, stock_quantity FROM products WHERE product_id = 301;
CALL GetCustomerOrderHistory(101);
CALL GetSalesReport('2026-09-01', '2026-09-30');
CALL GetSalesReport('2025-01-01', '2025-01-31');
CALL GetTopSellingProducts('2026-09-01', '2026-09-30');

