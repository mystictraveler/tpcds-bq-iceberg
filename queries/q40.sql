SELECT
  w_state,
  i_item_id,
  SUM(CASE WHEN d_date < DATE '2000-03-11' THEN cs_sales_price - COALESCE(cr_refunded_cash, 0.00) ELSE 0.00 END) AS sales_before,
  SUM(CASE WHEN d_date >= DATE '2000-03-11' THEN cs_sales_price - COALESCE(cr_refunded_cash, 0.00) ELSE 0.00 END) AS sales_after
FROM catalog_sales
LEFT JOIN catalog_returns ON cs_order_number = cr_order_number AND cs_item_sk = cr_item_sk
JOIN warehouse ON cs_warehouse_sk = w_warehouse_sk
JOIN item ON i_item_sk = cs_item_sk
JOIN date_dim ON cs_sold_date_sk = d_date_sk
WHERE i_current_price BETWEEN 0.99 AND 1.49
  AND d_date BETWEEN DATE_SUB(DATE '2000-03-11', INTERVAL 30 DAY) AND DATE_ADD(DATE '2000-03-11', INTERVAL 30 DAY)
GROUP BY w_state, i_item_id
ORDER BY w_state, i_item_id
LIMIT 100