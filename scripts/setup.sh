#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Rollback on error
function rollback_on_error() {
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "❗ [master] Error detected. Running cleanup/rollback..."
    scripts/cleanup.sh || true
  fi
  exit $rc
}
trap rollback_on_error ERR

echo "=== MASTER: Setup start ==="

# Load env
echo "🔹 [master] Loading .env.local"
export $(grep -v '^#' .env.local | xargs) || true

# Install deps
echo "🔹 [master] Installing Node dependencies..."
npm install --legacy-peer-deps

# Serverless & awslocal
command -v sls >/dev/null || npm install -g serverless
sls --version || true
command -v awslocal >/dev/null || { python3 -m pip install --user awscli-local; export PATH="$HOME/.local/bin:$PATH"; }

# Docker network
docker network inspect "$LAMBDA_DOCKER_NETWORK" >/dev/null 2>&1 || docker network create "$LAMBDA_DOCKER_NETWORK"

# Start LocalStack
docker-compose up -d
until docker exec localstack-main awslocal sts get-caller-identity >/dev/null 2>&1; do
  echo "   ⏳ Waiting for LocalStack..."
  sleep 3
done

# Ensure S3 deployment bucket
awslocal s3 mb s3://serverlessdeploymentbucket 2>/dev/null || true
sleep 2

# Pre-deploy: create topics
echo "🔹 [master] Creating SNS topics..."
source scripts/create-topics.sh

# Compile TypeScript
echo "🔹 [master] Compiling TypeScript..."
scripts/compile.sh

# Deploy Serverless stack
echo "🔹 [master] Deploying Serverless stack..."
scripts/deploy.sh

# Post-deploy: load queues/subscriptions/sample events
echo "🔹 [master] Loading data..."
source scripts/load-data.sh

API_ID=$(awslocal apigateway get-rest-apis | jq -r '.items[0].id')
echo "✅ System is ready!"
echo "POST /events -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/${API_ID}/events"
echo "POST /recommendations -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/${API_ID}/recommendations"

echo "=== MASTER: Done ==="
