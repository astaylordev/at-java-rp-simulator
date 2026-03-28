#!/usr/bin/env bash
# Bootstrap script — run once to set up remote state infrastructure and SSM secrets.
# Usage: AWS_PROFILE=your-scratch-profile bash env/scratch/bootstrap.sh

set -euo pipefail

REGION="ca-central-1"
SERVICE="java-rp-simulator"
ENV="scratch"
BUCKET="${SERVICE}-${ENV}-tf"
TABLE="${SERVICE}-${ENV}-tf-lock"
SECRET_PREFIX="${SERVICE}/${ENV}"

echo "==> Creating S3 bucket for Terraform state: ${BUCKET}"
if aws s3api head-bucket --bucket "${BUCKET}" --region "${REGION}" 2>/dev/null; then
  echo "    Bucket already exists, skipping."
else
  aws s3api create-bucket \
    --bucket "${BUCKET}" \
    --region "${REGION}" \
    --create-bucket-configuration LocationConstraint="${REGION}"

  aws s3api put-bucket-versioning \
    --bucket "${BUCKET}" \
    --versioning-configuration Status=Enabled

  aws s3api put-bucket-encryption \
    --bucket "${BUCKET}" \
    --server-side-encryption-configuration \
      '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

  aws s3api put-public-access-block \
    --bucket "${BUCKET}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

  echo "    Bucket created."
fi

echo ""
echo "==> Creating DynamoDB lock table: ${TABLE}"
if aws dynamodb describe-table --table-name "${TABLE}" --region "${REGION}" 2>/dev/null; then
  echo "    Table already exists, skipping."
else
  aws dynamodb create-table \
    --table-name "${TABLE}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
  echo "    Table created."
fi

echo ""
echo "==> Creating Secrets Manager secrets for OIDC credentials"
echo "    (Values are stored encrypted — never committed to source control)"
echo ""

printf "OIDC Client ID: "
read -r OIDC_CLIENT_ID

printf "OIDC Client Secret: "
read -rs OIDC_CLIENT_SECRET
echo ""

for SECRET_NAME in "${SECRET_PREFIX}/oidc-client-id" "${SECRET_PREFIX}/oidc-client-secret"; do
  if aws secretsmanager describe-secret --secret-id "${SECRET_NAME}" --region "${REGION}" > /dev/null 2>&1; then
    echo "    Secret ${SECRET_NAME} already exists, skipping creation."
  else
    aws secretsmanager create-secret \
      --name "${SECRET_NAME}" \
      --region "${REGION}" \
      --secret-string "placeholder" > /dev/null
    echo "    Created ${SECRET_NAME}."
  fi
done

aws secretsmanager put-secret-value \
  --secret-id "${SECRET_PREFIX}/oidc-client-id" \
  --secret-string "${OIDC_CLIENT_ID}" \
  --region "${REGION}" > /dev/null

aws secretsmanager put-secret-value \
  --secret-id "${SECRET_PREFIX}/oidc-client-secret" \
  --secret-string "${OIDC_CLIENT_SECRET}" \
  --region "${REGION}" > /dev/null

echo "    Secrets updated."

echo ""
echo "==> Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Build and push the Docker image to ECR:"
echo "     cd \$(git rev-parse --show-toplevel)"
echo "     aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin \$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${REGION}.amazonaws.com"
echo "     docker build -t rp-simulator ."
echo "     docker tag rp-simulator:latest \$(terraform -chdir=env/scratch/ecr output -raw repository_url):latest"
echo "     docker push \$(terraform -chdir=env/scratch/ecr output -raw repository_url):latest"
echo ""
echo "  2. Apply infrastructure in order:"
echo "     export OIDC_ISSUER_URI=https://your-idp/.well-known/openid-configuration"
echo "     export CONTAINER_IMAGE_TAG=latest"
echo "     (cd env/scratch/ecr && terragrunt apply)"
echo "     (cd env/scratch/networking && terragrunt apply)"
echo "     (cd env/scratch/ecs && terragrunt apply)"
echo ""
echo "  3. Register your redirect URI with your OIDC provider:"
echo "     https://\$(cd env/scratch/networking && terragrunt output -raw cloudfront_domain)/callback"
