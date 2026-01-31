WITH cs_ui AS (
  SELECT cs_item_sk, SUM(cs_ext_list_price) AS sale, SUM(cr_refunded_cash + cr_reversed_charge + cr_store_credit) AS refund
  FROM catalog_sales
  JOIN catalog_returns ON cs_item_sk = cr_item_sk AND cs_order_number = cr_order_number
  GROUP BY cs_item_sk
  HAVING SUM(cs_ext_list_price) > 2 * SUM(cr_refunded_cash + cr_reversed_charge + cr_store_credit)
),
cross_sales AS (
  SELECT
    i_product_name AS product_name, i_item_sk AS item_sk, s_store_name AS store_name, s_zip AS store_zip,
    ad1.ca_street_number AS b_street_number, ad1.ca_street_name AS b_street_name, ad1.ca_city AS b_city,
    ad1.ca_zip AS b_zip,
    ad2.ca_street_number AS c_street_number, ad2.ca_street_name AS c_street_name, ad2.ca_city AS c_city,
    ad2.ca_zip AS c_zip,
    d1.d_year AS syear, d1.d_qoy AS s_qoy, d2.d_year AS byear, d2.d_qoy AS b_qoy,
    c1.c_current_addr_sk AS c1_addr_sk, c2.c_current_addr_sk AS c2_addr_sk,
    SUM(ss_ext_sales_price) AS store_sales, SUM(ss_net_profit) AS store_cost,
    SUM(ss2.ss_ext_sales_price) AS store_sales2, SUM(ss2.ss_net_profit) AS store_cost2
  FROM store_sales ss1
  JOIN store_sales ss2 ON ss1.ss_store_sk = ss2.ss_store_sk
    AND ss1.ss_item_sk = ss2.ss_item_sk
    AND ss1.ss_customer_sk <> ss2.ss_customer_sk
  JOIN store ON ss1.ss_store_sk = s_store_sk
  JOIN customer c1 ON ss1.ss_customer_sk = c1.c_customer_sk
  JOIN customer c2 ON ss2.ss_customer_sk = c2.c_customer_sk
  JOIN customer_address ad1 ON c1.c_current_addr_sk = ad1.ca_address_sk
  JOIN customer_address ad2 ON c2.c_current_addr_sk = ad2.ca_address_sk
  JOIN item ON ss1.ss_item_sk = i_item_sk
  JOIN date_dim d1 ON ss1.ss_sold_date_sk = d1.d_date_sk
  JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
  JOIN cs_ui ON ss1.ss_item_sk = cs_ui.cs_item_sk
  JOIN income_band ib1 ON c1.c_first_sales_date_sk = ib1.ib_lower_bound
  JOIN income_band ib2 ON c2.c_first_sales_date_sk = ib2.ib_lower_bound
  WHERE i_current_price BETWEEN 64 AND 64 + 10
    AND i_current_price BETWEEN 64 + 1 AND 64 + 15
    AND i_color IN ('purple', 'burlywood', 'indian', 'spring', 'floral', 'medium')
    AND d1.d_year = 1999
  GROUP BY i_product_name, i_item_sk, s_store_name, s_zip,
    ad1.ca_street_number, ad1.ca_street_name, ad1.ca_city, ad1.ca_zip,
    ad2.ca_street_number, ad2.ca_street_name, ad2.ca_city, ad2.ca_zip,
    d1.d_year, d1.d_qoy, d2.d_year, d2.d_qoy,
    c1.c_current_addr_sk, c2.c_current_addr_sk
)
SELECT cs1.product_name, cs1.store_name, cs1.store_zip,
  cs1.b_street_number, cs1.b_street_name, cs1.b_city, cs1.b_zip,
  cs1.c_street_number, cs1.c_street_name, cs1.c_city, cs1.c_zip,
  cs1.syear, cs1.store_sales, cs1.store_cost,
  cs2.store_sales AS store_sales2, cs2.store_cost AS store_cost2
FROM cross_sales cs1
JOIN cross_sales cs2
  ON cs1.item_sk = cs2.item_sk
  AND cs1.store_name = cs2.store_name
  AND cs1.store_zip = cs2.store_zip
WHERE cs2.syear = 1999 + 1
  AND cs1.syear = 1999
ORDER BY cs1.product_name, cs1.store_name, cs2.store_sales, cs2.store_cost,
  cs1.b_street_number, cs1.b_street_name, cs1.b_city, cs1.b_zip,
  cs1.c_street_number, cs1.c_street_name, cs1.c_city, cs1.c_zip