#!/usr/bin/env bash
set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-aws-sandbox}"
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="605618833247"
BUCKET_NAME="tpcds-iceberg-sf10-${AWS_ACCOUNT_ID}"
GLUE_DB="tpcds_sf10"
BQ_ROLE_NAME="bigquery-omni-connection"

export AWS_PROFILE

echo "=== Step 1: Create S3 bucket ==="
if aws s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
  echo "Bucket s3://${BUCKET_NAME} already exists"
else
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --no-cli-pager
  echo "Created bucket s3://${BUCKET_NAME}"
fi

echo "=== Step 2: Create Glue database ==="
aws glue create-database \
  --region "$AWS_REGION" \
  --database-input "{\"Name\": \"${GLUE_DB}\", \"Description\": \"TPC-DS SF10 Iceberg tables for BigQuery cross-cloud benchmark\"}" \
  --no-cli-pager 2>/dev/null || echo "Glue database '${GLUE_DB}' already exists"

echo "=== Step 3: Create IAM role for BigQuery Omni ==="
TRUST_POLICY=$(cat <<'POLICY'
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
          "accounts.google.com:sub": "PLACEHOLDER_GOOGLE_IDENTITY"
        }
      }
    }
  ]
}
POLICY
)

S3_POLICY=$(cat <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::${BUCKET_NAME}",
        "arn:aws:s3:::${BUCKET_NAME}/*"
      ]
    }
  ]
}
POLICY
)

# Create or update the IAM role
if aws iam get-role --role-name "$BQ_ROLE_NAME" --no-cli-pager 2>/dev/null; then
  echo "IAM role '${BQ_ROLE_NAME}' already exists"
else
  aws iam create-role \
    --role-name "$BQ_ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --description "Role for BigQuery Omni cross-cloud access to TPC-DS Iceberg tables" \
    --no-cli-pager
  echo "Created IAM role '${BQ_ROLE_NAME}'"
fi

# Attach inline policy for S3 access
aws iam put-role-policy \
  --role-name "$BQ_ROLE_NAME" \
  --policy-name "tpcds-s3-read" \
  --policy-document "$S3_POLICY" \
  --no-cli-pager
echo "Attached S3 read policy to role"

ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${BQ_ROLE_NAME}"
echo ""
echo "=== AWS Setup Complete ==="
echo "Bucket:    s3://${BUCKET_NAME}"
echo "Glue DB:   ${GLUE_DB}"
echo "Role ARN:  ${ROLE_ARN}"
echo ""
echo "NEXT: After creating the BigQuery connection (setup_gcp.sh),"
echo "update the trust policy with the Google identity:"
echo "  aws iam update-assume-role-policy --role-name ${BQ_ROLE_NAME} --policy-document <updated-trust-policy>"
