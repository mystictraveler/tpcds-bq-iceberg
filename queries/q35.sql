SELECT
  ca_state,
  cd_gender,
  cd_marital_status,
  cd_dep_count,
  COUNT(*) AS cnt1,
  AVG(cd_dep_count) AS avg_dep_count,
  MAX(cd_dep_count) AS max_dep_count,
  SUM(cd_dep_count) AS sum_dep_count,
  cd_dep_employed_count,
  COUNT(*) AS cnt2,
  AVG(cd_dep_employed_count) AS avg_dep_employed_count,
  MAX(cd_dep_employed_count) AS max_dep_employed_count,
  SUM(cd_dep_employed_count) AS sum_dep_employed_count,
  cd_dep_college_count,
  COUNT(*) AS cnt3,
  AVG(cd_dep_college_count) AS avg_dep_college_count,
  MAX(cd_dep_college_count) AS max_dep_college_count,
  SUM(cd_dep_college_count) AS sum_dep_college_count
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE EXISTS (
  SELECT 1 FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE c.c_customer_sk = ss.ss_customer_sk AND d.d_year = 2002 AND d.d_qoy < 4
)
AND (
  EXISTS (
    SELECT 1 FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE c.c_customer_sk = ws.ws_bill_customer_sk AND d.d_year = 2002 AND d.d_qoy < 4
  )
  OR EXISTS (
    SELECT 1 FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE c.c_customer_sk = cs.cs_bill_customer_sk AND d.d_year = 2002 AND d.d_qoy < 4
  )
)
GROUP BY ca_state, cd_gender, cd_marital_status, cd_dep_count,
         cd_dep_employed_count, cd_dep_college_count
ORDER BY ca_state, cd_gender, cd_marital_status, cd_dep_count,
         cd_dep_employed_count, cd_dep_college_count
LIMIT 100