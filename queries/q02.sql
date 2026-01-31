WITH wscs AS (
  SELECT sold_date_sk, sales_price
  FROM (
    SELECT ws_sold_date_sk AS sold_date_sk, ws_ext_sales_price AS sales_price
    FROM web_sales
    UNION ALL
    SELECT cs_sold_date_sk AS sold_date_sk, cs_ext_sales_price AS sales_price
    FROM catalog_sales
  ) x
),
wswscs AS (
  SELECT
    d_week_seq,
    SUM(CASE WHEN d_day_name = 'Sunday' THEN sales_price ELSE NULL END) AS sun_sales,
    SUM(CASE WHEN d_day_name = 'Monday' THEN sales_price ELSE NULL END) AS mon_sales,
    SUM(CASE WHEN d_day_name = 'Tuesday' THEN sales_price ELSE NULL END) AS tue_sales,
    SUM(CASE WHEN d_day_name = 'Wednesday' THEN sales_price ELSE NULL END) AS wed_sales,
    SUM(CASE WHEN d_day_name = 'Thursday' THEN sales_price ELSE NULL END) AS thu_sales,
    SUM(CASE WHEN d_day_name = 'Friday' THEN sales_price ELSE NULL END) AS fri_sales,
    SUM(CASE WHEN d_day_name = 'Saturday' THEN sales_price ELSE NULL END) AS sat_sales
  FROM wscs
  JOIN date_dim ON sold_date_sk = d_date_sk
  GROUP BY d_week_seq
)
SELECT
  y.d_week_seq1,
  ROUND(y.sun_sales1 / z.sun_sales2, 2) AS sun_ratio,
  ROUND(y.mon_sales1 / z.mon_sales2, 2) AS mon_ratio,
  ROUND(y.tue_sales1 / z.tue_sales2, 2) AS tue_ratio,
  ROUND(y.wed_sales1 / z.wed_sales2, 2) AS wed_ratio,
  ROUND(y.thu_sales1 / z.thu_sales2, 2) AS thu_ratio,
  ROUND(y.fri_sales1 / z.fri_sales2, 2) AS fri_ratio,
  ROUND(y.sat_sales1 / z.sat_sales2, 2) AS sat_ratio
FROM (
  SELECT
    wswscs.d_week_seq AS d_week_seq1,
    sun_sales AS sun_sales1,
    mon_sales AS mon_sales1,
    tue_sales AS tue_sales1,
    wed_sales AS wed_sales1,
    thu_sales AS thu_sales1,
    fri_sales AS fri_sales1,
    sat_sales AS sat_sales1
  FROM wswscs
  JOIN date_dim ON wswscs.d_week_seq = date_dim.d_week_seq
  WHERE d_year = 2001
) y
JOIN (
  SELECT
    wswscs.d_week_seq AS d_week_seq2,
    sun_sales AS sun_sales2,
    mon_sales AS mon_sales2,
    tue_sales AS tue_sales2,
    wed_sales AS wed_sales2,
    thu_sales AS thu_sales2,
    fri_sales AS fri_sales2,
    sat_sales AS sat_sales2
  FROM wswscs
  JOIN date_dim ON wswscs.d_week_seq = date_dim.d_week_seq
  WHERE d_year = 2001 + 1
) z
ON y.d_week_seq1 = z.d_week_seq2 - 53
ORDER BY y.d_week_seq1