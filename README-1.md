# JForce Solutions — SQL Developer Task 2




## Files
- `database.sql`: recreates `jforce_ecommerce`, creates four related tables, inserts 8 customers, 15 products, 15 orders and 33 order items.
- `procedures.sql`: six required stored procedures and the optional top-selling-products procedure.
- `demo_queries.sql`: ready-to-run example and validation calls.


```bash
mysql -u root -p < database.sql
mysql -u root -p < procedures.sql
mysql -u root -p < demo_queries.sql
```

## Stored procedures
1. `SearchProducts(category, max_price)`: active products, optional category (NULL or empty string), price ascending.
2. `CheckStock(product_id, requested_quantity)`: validates quantity and product, returns sufficient/insufficient; inactive products are insufficient.
3. `PlaceOrder(customer_id, product_id, quantity)`: checks active customer/product and available stock, locks rows, inserts pending order/item, deducts stock and commits atomically. Uses an exception handler to roll back failures.
4. `CancelOrder(order_id)`: locks a pending order, restores stock for **all** its items, changes status and commits. Already completed/cancelled orders cannot be cancelled.
5. `GetCustomerOrderHistory(customer_id)`: joins four tables, combines item names and quantities per order, newest first.
6. `GetSalesReport(start_date, end_date)`: completed orders only, count, units, sales and average order value; returns zeroes for no-sales periods.





