SELECT
  s_store_id,
  SUM(ss_net_profit) / SUM(ss_ext_sales_price) AS gross_margin,
  i_category,
  RANK() OVER (PARTITION BY i_category ORDER BY SUM(ss_net_profit) / SUM(ss_ext_sales_price)) AS rank_within_parent
FROM store_sales
JOIN date_dim ON d_date_sk = ss_sold_date_sk
JOIN item ON i_item_sk = ss_item_sk
JOIN store ON s_store_sk = ss_store_sk
WHERE d_year = 2001
  AND s_state IN ('TN', 'TN', 'TN', 'TN', 'TN', 'TN', 'TN', 'TN')
GROUP BY ROLLUP(i_category, s_store_id)
ORDER BY
  i_category,
  rank_within_parent
LIMIT 100