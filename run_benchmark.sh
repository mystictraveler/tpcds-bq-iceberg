#!/usr/bin/env bash
set -euo pipefail

GCP_PROJECT="project-8a24c789-9c25-4f79-8ef"
BQ_LOCATION="aws-us-east-1"
DATASET="tpcds_sf10"
QUERIES_DIR="$(dirname "$0")/queries"
RESULTS_DIR="$(dirname "$0")/results"
RESULTS_FILE="${RESULTS_DIR}/benchmark_results.csv"

mkdir -p "$RESULTS_DIR"

echo "query,status,duration_sec,bytes_scanned,error" > "$RESULTS_FILE"

QUERIES="${1:-$(seq -w 1 99)}"

echo "=== TPC-DS SF10 Benchmark on BigQuery (Iceberg/AWS) ==="
echo "Project:  ${GCP_PROJECT}"
echo "Dataset:  ${DATASET}"
echo "Location: ${BQ_LOCATION}"
echo ""

TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_TIME=0

for Q_NUM in $QUERIES; do
  Q_FILE="${QUERIES_DIR}/q${Q_NUM}.sql"
  if [[ ! -f "$Q_FILE" ]]; then
    echo "SKIP q${Q_NUM}: file not found"
    continue
  fi

  # Prepend dataset to all table references
  SQL=$(cat "$Q_FILE")
  # Wrap table names with dataset prefix by using a WITH clause approach
  # Instead, we set the default dataset via bq flag

  echo -n "Running q${Q_NUM}... "
  START=$(date +%s%N)

  OUTPUT=$(bq query \
    --use_legacy_sql=false \
    --location="$BQ_LOCATION" \
    --project_id="$GCP_PROJECT" \
    --dataset_id="$DATASET" \
    --format=json \
    --max_rows=0 \
    --nouse_cache \
    "$SQL" 2>&1) && STATUS="PASS" || STATUS="FAIL"

  END=$(date +%s%N)
  DURATION=$(echo "scale=3; ($END - $START) / 1000000000" | bc)

  # Try to extract bytes scanned from job stats
  BYTES="N/A"
  if [[ "$STATUS" == "PASS" ]]; then
    TOTAL_PASS=$((TOTAL_PASS + 1))
    echo "PASS (${DURATION}s)"
  else
    TOTAL_FAIL=$((TOTAL_FAIL + 1))
    ERROR=$(echo "$OUTPUT" | head -1 | tr ',' ';')
    echo "FAIL (${DURATION}s) - ${ERROR}"
  fi

  TOTAL_TIME=$(echo "$TOTAL_TIME + $DURATION" | bc)
  ERROR_MSG=""
  [[ "$STATUS" == "FAIL" ]] && ERROR_MSG=$(echo "$OUTPUT" | head -1 | tr ',' ';' | tr '"' "'")
  echo "q${Q_NUM},${STATUS},${DURATION},${BYTES},\"${ERROR_MSG}\"" >> "$RESULTS_FILE"
done

echo ""
echo "=== Benchmark Summary ==="
echo "Passed: ${TOTAL_PASS}"
echo "Failed: ${TOTAL_FAIL}"
echo "Total time: ${TOTAL_TIME}s"
echo "Results: ${RESULTS_FILE}"
