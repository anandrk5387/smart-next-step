#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Rollback on error
function rollback_on_error() {
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "❗ Error detected. Running cleanup..."
    scripts/cleanup.sh || true
  fi
  exit $rc
}
trap rollback_on_error ERR

echo "=== Setup: Start ==="

# Load env
echo "🔹 Loading .env.local"
export $(grep -v '^#' .env.local | xargs) || true

# Install Node deps
echo "🔹 Installing dependencies..."
npm install --legacy-peer-deps

# Ensure serverless & awslocal
command -v sls >/dev/null || npm install -g serverless
command -v awslocal >/dev/null || { python3 -m pip install --user awscli-local; export PATH="$HOME/.local/bin:$PATH"; }

# Docker network for Lambdas
docker network inspect "$LAMBDA_DOCKER_NETWORK" >/dev/null 2>&1 || docker network create "$LAMBDA_DOCKER_NETWORK"

# Start LocalStack
docker-compose up -d
until docker exec localstack-main awslocal sts get-caller-identity >/dev/null 2>&1; do
  echo "   ⏳ Waiting for LocalStack..."
  sleep 2
done

# Ensure deployment bucket exists
awslocal s3 mb s3://serverlessdeploymentbucket 2>/dev/null || true
sleep 2

# Pre-deploy: create SNS topics only once
echo "🔹 Creating SNS topics..."
source scripts/create-topics.sh || true

# Compile TS
echo "🔹 Compiling TypeScript..."
scripts/compile.sh

# Deploy Serverless stack
echo "🔹 Deploying Serverless stack..."
scripts/deploy.sh

# Post-deploy: load sample data / subscribe queues
echo "🔹 Loading sample data..."
source scripts/load-data.sh || true

API_ID=$(awslocal apigateway get-rest-apis | jq -r '.items[0].id')
echo "✅ System ready!"
echo "POST /events -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/${API_ID}/events"
echo "POST /recommendations -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/${API_ID}/recommendations"
echo "=== Setup: Done ==="
