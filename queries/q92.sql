SELECT SUM(ws_ext_discount_amt) AS excess_discount_amount
FROM web_sales
JOIN item ON i_item_sk = ws_item_sk
JOIN date_dim ON d_date_sk = ws_sold_date_sk
WHERE i_manufact_id = 350
  AND d_date BETWEEN DATE '2000-01-27' AND DATE_ADD(DATE '2000-01-27', INTERVAL 90 DAY)
  AND ws_ext_discount_amt > (
    SELECT 1.3 * AVG(ws_ext_discount_amt)
    FROM web_sales
    JOIN date_dim ON d_date_sk = ws_sold_date_sk
    WHERE ws_item_sk = i_item_sk
      AND d_date BETWEEN DATE '2000-01-27' AND DATE_ADD(DATE '2000-01-27', INTERVAL 90 DAY)
  )
ORDER BY SUM(ws_ext_discount_amt)
LIMIT 100