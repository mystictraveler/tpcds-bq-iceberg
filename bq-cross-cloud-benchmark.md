# TPC-DS SF10 Cross-Cloud Benchmark: BigQuery → Iceberg on AWS

**GCP Project:** `project-8a24c789-9c25-4f79-8ef` (BQ Cross-Cloud Benchmark)
**Scale:** SF10 (10 GB)
**Architecture:** Data lives as Iceberg tables in AWS S3 (Glue catalog) → Queried from BigQuery via Omni

## Step 1: AWS Setup — S3 Bucket & Glue Database

- Create S3 bucket: `s3://tpcds-iceberg-sf10/` (us-east-1)
- Create Glue database: `tpcds_sf10`
- Create IAM role for BigQuery cross-cloud access with S3 read permissions

## Step 2: Generate TPC-DS SF10 Data as Iceberg Tables in AWS

Use DuckDB locally to generate data, then use PySpark + Iceberg to write as Iceberg tables to S3 with Glue catalog:

1. **Generate with DuckDB:**
   - `INSTALL tpcds; LOAD tpcds; CALL dsdgen(sf=10);`
   - Export all 24 tables as Parquet files locally

2. **Write as Iceberg tables to S3/Glue:**
   - Use PySpark with `iceberg-spark-runtime` and `iceberg-aws` dependencies
   - Configure Spark with Glue catalog (`org.apache.iceberg.aws.glue.GlueCatalog`)
   - Read each Parquet file → write as Iceberg table to `s3://tpcds-iceberg-sf10/<table>/`
   - Tables registered in Glue database `tpcds_sf10`

## Step 3: GCP Setup — BigQuery Omni Connection

- Set project: `gcloud config set project project-8a24c789-9c25-4f79-8ef`
- Create BigQuery AWS connection in `aws-us-east-1` region
- Update AWS IAM role trust policy with the BigQuery Google identity
- Create federated dataset from Glue:
  ```sql
  CREATE EXTERNAL SCHEMA tpcds_sf10
  WITH CONNECTION `project.aws-us-east-1.aws_connection`
  OPTIONS (
    external_source = 'aws-glue://arn:aws:glue:us-east-1:ACCOUNT_ID:database/tpcds_sf10',
    location = 'aws-us-east-1'
  );
  ```

## Step 4: Run 99 TPC-DS Queries from BigQuery

- Adapt TPC-DS queries for BigQuery SQL dialect and federated dataset name
- Run all 99 queries via `bq query`, capture execution time and bytes scanned
- Output results as a summary table (query, status, duration, bytes scanned)

## Deliverables

Directory: `tpcds-bq-iceberg/`

1. `setup_aws.sh` — Creates S3 bucket, Glue database, IAM role
2. `generate_data.py` — DuckDB generation + PySpark Iceberg write to S3/Glue
3. `setup_gcp.sh` — Creates BQ connection, federated dataset
4. `queries/` — All 99 TPC-DS queries adapted for BigQuery
5. `run_benchmark.sh` — Executes all queries and reports timing
6. `results/` — Output directory for benchmark results

## Verification

- Validate row counts per table via both Glue (Athena/Spark) and BigQuery
- Run q1, q3, q7 first to verify correctness
- Confirm Iceberg metadata visible in S3 and Glue console
