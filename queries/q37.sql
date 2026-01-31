SELECT i_item_id, i_item_desc, i_current_price
FROM item
JOIN inventory ON inv_item_sk = i_item_sk
JOIN date_dim ON d_date_sk = inv_date_sk
JOIN catalog_sales ON cs_item_sk = i_item_sk
WHERE i_current_price BETWEEN 68.00 AND 98.00
  AND d_date BETWEEN DATE '2000-02-01' AND DATE_ADD(DATE '2000-02-01', INTERVAL 60 DAY)
  AND inv_quantity_on_hand BETWEEN 100 AND 500
  AND i_manufact_id IN (677, 940, 694, 808)
GROUP BY i_item_id, i_item_desc, i_current_price
ORDER BY i_item_id
LIMIT 100