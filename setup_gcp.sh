#!/usr/bin/env bash
set -euo pipefail

GCP_PROJECT="project-8a24c789-9c25-4f79-8ef"
AWS_ACCOUNT_ID="605618833247"
AWS_REGION="us-east-1"
BQ_LOCATION="aws-us-east-1"
CONNECTION_ID="aws-tpcds-connection"
BQ_ROLE_NAME="bigquery-omni-connection"
GLUE_DB="tpcds_sf10"
DATASET_NAME="tpcds_sf10"

gcloud config set project "$GCP_PROJECT"

echo "=== Step 1: Create BigQuery connection to AWS ==="
# Check if connection exists
if bq show --connection --location="$BQ_LOCATION" "$CONNECTION_ID" 2>/dev/null; then
  echo "Connection '${CONNECTION_ID}' already exists"
else
  bq mk --connection \
    --connection_type='AWS' \
    --iam_role_id="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${BQ_ROLE_NAME}" \
    --location="$BQ_LOCATION" \
    "$CONNECTION_ID"
  echo "Created connection '${CONNECTION_ID}'"
fi

echo ""
echo "=== Step 2: Get Google identity for trust policy update ==="
GOOGLE_IDENTITY=$(bq show --connection --location="$BQ_LOCATION" --format=json "$CONNECTION_ID" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['aws']['accessRole']['iamRoleId'])" 2>/dev/null \
  || echo "COULD_NOT_EXTRACT")

echo "Google Identity: ${GOOGLE_IDENTITY}"
echo ""
echo "Update the AWS IAM trust policy with this identity:"
echo ""

TRUST_POLICY=$(cat <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "accounts.google.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "accounts.google.com:sub": "${GOOGLE_IDENTITY}"
        }
      }
    }
  ]
}
POLICY
)

echo "$TRUST_POLICY"
echo ""
read -p "Press Enter after updating the AWS trust policy (or type 'auto' to update automatically): " RESPONSE

if [[ "$RESPONSE" == "auto" ]]; then
  TMPFILE=$(mktemp)
  echo "$TRUST_POLICY" > "$TMPFILE"
  AWS_PROFILE="${AWS_PROFILE:-aws-sandbox}" aws iam update-assume-role-policy \
    --role-name "$BQ_ROLE_NAME" \
    --policy-document "file://${TMPFILE}" \
    --region "$AWS_REGION"
  rm "$TMPFILE"
  echo "AWS trust policy updated automatically."
fi

echo ""
echo "=== Step 3: Create federated dataset from AWS Glue ==="
GLUE_ARN="aws-glue://arn:aws:glue:${AWS_REGION}:${AWS_ACCOUNT_ID}:database/${GLUE_DB}"
CONNECTION_PATH="${GCP_PROJECT}.${BQ_LOCATION}.${CONNECTION_ID}"

bq query --use_legacy_sql=false --location="$BQ_LOCATION" \
  "CREATE EXTERNAL SCHEMA IF NOT EXISTS \`${DATASET_NAME}\`
   WITH CONNECTION \`${CONNECTION_PATH}\`
   OPTIONS (
     external_source = '${GLUE_ARN}',
     location = '${BQ_LOCATION}'
   );" 2>/dev/null || \
bq query --use_legacy_sql=false --location="$BQ_LOCATION" \
  "CREATE SCHEMA IF NOT EXISTS \`${DATASET_NAME}\`
   OPTIONS (
     location = '${BQ_LOCATION}'
   );"

echo ""
echo "=== GCP Setup Complete ==="
echo "Project:    ${GCP_PROJECT}"
echo "Connection: ${CONNECTION_ID} (${BQ_LOCATION})"
echo "Dataset:    ${DATASET_NAME}"
echo ""
echo "You can now run the benchmark: ./run_benchmark.sh"
