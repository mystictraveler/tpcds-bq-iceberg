SELECT SUM(cs_ext_discount_amt) AS excess_discount_amount
FROM catalog_sales
JOIN item ON i_item_sk = cs_item_sk
JOIN date_dim ON d_date_sk = cs_sold_date_sk
WHERE i_manufact_id = 977
  AND d_date BETWEEN DATE '2000-01-27' AND DATE_ADD(DATE '2000-01-27', INTERVAL 90 DAY)
  AND cs_ext_discount_amt > (
    SELECT 1.3 * AVG(cs_ext_discount_amt)
    FROM catalog_sales
    JOIN date_dim ON d_date_sk = cs_sold_date_sk
    WHERE cs_item_sk = i_item_sk
      AND d_date BETWEEN DATE '2000-01-27' AND DATE_ADD(DATE '2000-01-27', INTERVAL 90 DAY)
  )
LIMIT 100