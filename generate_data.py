#!/usr/bin/env python3
"""
Generate TPC-DS SF10 data with DuckDB and write as Iceberg tables to S3/Glue.

Usage:
    pip install duckdb pyarrow pyspark
    python generate_data.py
"""
import os
import sys
import subprocess
import tempfile
import shutil

AWS_PROFILE = os.environ.get("AWS_PROFILE", "aws-sandbox")
AWS_REGION = "us-east-1"
AWS_ACCOUNT_ID = "605618833247"
BUCKET_NAME = f"tpcds-iceberg-sf10-{AWS_ACCOUNT_ID}"
GLUE_DB = "tpcds_sf10"
SCALE_FACTOR = 10

TPCDS_TABLES = [
    "call_center", "catalog_page", "catalog_returns", "catalog_sales",
    "customer", "customer_address", "customer_demographics", "date_dim",
    "household_demographics", "income_band", "inventory", "item",
    "promotion", "reason", "ship_mode", "store", "store_returns",
    "store_sales", "time_dim", "warehouse", "web_page", "web_returns",
    "web_sales", "web_site",
]


def generate_parquet_with_duckdb(output_dir: str):
    """Generate TPC-DS data using DuckDB and export as Parquet."""
    import duckdb

    con = duckdb.connect()
    con.execute("INSTALL tpcds; LOAD tpcds;")
    print(f"Generating TPC-DS SF{SCALE_FACTOR} data...")
    con.execute(f"CALL dsdgen(sf={SCALE_FACTOR});")

    for table in TPCDS_TABLES:
        out_path = os.path.join(output_dir, f"{table}.parquet")
        count = con.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"  Exporting {table} ({count:,} rows) -> {out_path}")
        con.execute(f"COPY {table} TO '{out_path}' (FORMAT PARQUET, COMPRESSION ZSTD);")

    con.close()
    print("DuckDB export complete.")


def upload_to_s3(parquet_dir: str):
    """Upload Parquet files to S3."""
    print(f"\nUploading Parquet files to s3://{BUCKET_NAME}/parquet/...")
    subprocess.run(
        [
            "aws", "s3", "sync", parquet_dir,
            f"s3://{BUCKET_NAME}/parquet/",
            "--profile", AWS_PROFILE,
            "--region", AWS_REGION,
        ],
        check=True,
    )
    print("S3 upload complete.")


def write_iceberg_tables():
    """Use PySpark to read Parquet from S3 and write as Iceberg tables to S3/Glue."""
    from pyspark.sql import SparkSession

    spark = (
        SparkSession.builder
        .appName("tpcds-iceberg-load")
        .config("spark.driver.memory", "8g")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.catalog.glue_catalog", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.glue_catalog.catalog-impl", "org.apache.iceberg.aws.glue.GlueCatalog")
        .config("spark.sql.catalog.glue_catalog.warehouse", f"s3://{BUCKET_NAME}/iceberg/")
        .config("spark.sql.catalog.glue_catalog.io-impl", "org.apache.iceberg.aws.s3.S3FileIO")
        .config("spark.hadoop.fs.s3a.aws.credentials.provider",
                "com.amazonaws.auth.profile.ProfileCredentialsProvider")
        .config("spark.hadoop.aws.profile", AWS_PROFILE)
        .config("spark.jars.packages",
                "org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.5.2,"
                "org.apache.iceberg:iceberg-aws-bundle:1.5.2,"
                "software.amazon.awssdk:bundle:2.20.18,"
                "org.apache.hadoop:hadoop-aws:3.3.4")
        .config("spark.hadoop.fs.s3a.impl", "org.apache.hadoop.fs.s3a.S3AFileSystem")
        .config("spark.hadoop.fs.s3a.aws.credentials.provider",
                "com.amazonaws.auth.profile.ProfileCredentialsProvider")
        .getOrCreate()
    )

    # Create Glue database if not exists
    spark.sql(f"CREATE DATABASE IF NOT EXISTS glue_catalog.{GLUE_DB}")

    parquet_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "parquet_data")

    for table in TPCDS_TABLES:
        local_path = os.path.join(parquet_dir, f"{table}.parquet")
        iceberg_table = f"glue_catalog.{GLUE_DB}.{table}"

        print(f"  Writing Iceberg table: {iceberg_table}")
        df = spark.read.parquet(local_path)
        df.writeTo(iceberg_table).using("iceberg").createOrReplace()
        count = spark.table(iceberg_table).count()
        print(f"    -> {count:,} rows")

    spark.stop()
    print("\nAll Iceberg tables created in Glue catalog.")


def main():
    step = sys.argv[1] if len(sys.argv) > 1 else "all"

    if step in ("all", "generate"):
        parquet_dir = os.path.join(os.path.dirname(__file__), "parquet_data")
        os.makedirs(parquet_dir, exist_ok=True)
        generate_parquet_with_duckdb(parquet_dir)

        if step == "all":
            upload_to_s3(parquet_dir)
    elif step == "upload":
        parquet_dir = os.path.join(os.path.dirname(__file__), "parquet_data")
        upload_to_s3(parquet_dir)

    if step in ("all", "iceberg"):
        write_iceberg_tables()

    print("\nDone! Steps: generate -> upload -> iceberg")
    print("Run individual steps: python generate_data.py [generate|upload|iceberg]")


if __name__ == "__main__":
    main()
