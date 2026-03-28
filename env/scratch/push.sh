#!/usr/bin/env bash
# Build and push the Docker image to ECR.
# Usage: bash env/scratch/push.sh [image-tag]
#   image-tag defaults to "latest"

set -euo pipefail

export AWS_PAGER=""

REGION="ca-central-1"
SERVICE="java-rp-simulator"
TAG="${1:-latest}"

REPO_ROOT="$(git rev-parse --show-toplevel)"
ECR_URL="$(cd "${REPO_ROOT}/env/scratch/ecr" && terragrunt output -raw repository_url)"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

echo "==> Authenticating Docker to ECR"
aws ecr get-login-password --region "${REGION}" \
  | docker login --username AWS --password-stdin "${ECR_REGISTRY}"

echo ""
echo "==> Building image: ${SERVICE}:${TAG}"
docker build --platform linux/amd64 -t "${SERVICE}:${TAG}" "${REPO_ROOT}"

echo ""
echo "==> Tagging and pushing to ${ECR_URL}:${TAG}"
docker tag "${SERVICE}:${TAG}" "${ECR_URL}:${TAG}"
docker push "${ECR_URL}:${TAG}"

echo ""
echo "==> Done. To deploy, run:"
echo "    export OIDC_ISSUER_URI=https://your-idp/.well-known/openid-configuration"
echo "    export CONTAINER_IMAGE_TAG=${TAG}"
echo "    (cd env/scratch/networking && terragrunt apply)"
echo "    (cd env/scratch/ecs && terragrunt apply)"
