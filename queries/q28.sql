SELECT *
FROM (
  SELECT AVG(ss_list_price) AS b1_lp, COUNT(ss_list_price) AS b1_cnt, COUNT(DISTINCT ss_list_price) AS b1_cntd
  FROM store_sales
  WHERE ss_quantity BETWEEN 0 AND 5
    AND (ss_list_price BETWEEN 8.00 AND 18.00
      OR ss_coupon_amt BETWEEN 459.00 AND 1459.00
      OR ss_wholesale_cost BETWEEN 57.00 AND 77.00)
) b1
CROSS JOIN (
  SELECT AVG(ss_list_price) AS b2_lp, COUNT(ss_list_price) AS b2_cnt, COUNT(DISTINCT ss_list_price) AS b2_cntd
  FROM store_sales
  WHERE ss_quantity BETWEEN 6 AND 10
    AND (ss_list_price BETWEEN 90.00 AND 100.00
      OR ss_coupon_amt BETWEEN 2323.00 AND 3323.00
      OR ss_wholesale_cost BETWEEN 31.00 AND 51.00)
) b2
CROSS JOIN (
  SELECT AVG(ss_list_price) AS b3_lp, COUNT(ss_list_price) AS b3_cnt, COUNT(DISTINCT ss_list_price) AS b3_cntd
  FROM store_sales
  WHERE ss_quantity BETWEEN 11 AND 15
    AND (ss_list_price BETWEEN 142.00 AND 152.00
      OR ss_coupon_amt BETWEEN 12214.00 AND 13214.00
      OR ss_wholesale_cost BETWEEN 79.00 AND 99.00)
) b3
CROSS JOIN (
  SELECT AVG(ss_list_price) AS b4_lp, COUNT(ss_list_price) AS b4_cnt, COUNT(DISTINCT ss_list_price) AS b4_cntd
  FROM store_sales
  WHERE ss_quantity BETWEEN 16 AND 20
    AND (ss_list_price BETWEEN 135.00 AND 145.00
      OR ss_coupon_amt BETWEEN 6071.00 AND 7071.00
      OR ss_wholesale_cost BETWEEN 38.00 AND 58.00)
) b4
CROSS JOIN (
  SELECT AVG(ss_list_price) AS b5_lp, COUNT(ss_list_price) AS b5_cnt, COUNT(DISTINCT ss_list_price) AS b5_cntd
  FROM store_sales
  WHERE ss_quantity BETWEEN 21 AND 25
    AND (ss_list_price BETWEEN 122.00 AND 132.00
      OR ss_coupon_amt BETWEEN 836.00 AND 1836.00
      OR ss_wholesale_cost BETWEEN 17.00 AND 37.00)
) b5
CROSS JOIN (
  SELECT AVG(ss_list_price) AS b6_lp, COUNT(ss_list_price) AS b6_cnt, COUNT(DISTINCT ss_list_price) AS b6_cntd
  FROM store_sales
  WHERE ss_quantity BETWEEN 26 AND 30
    AND (ss_list_price BETWEEN 154.00 AND 164.00
      OR ss_coupon_amt BETWEEN 7326.00 AND 8326.00
      OR ss_wholesale_cost BETWEEN 7.00 AND 27.00)
) b6
LIMIT 100
