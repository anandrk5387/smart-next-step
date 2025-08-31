#!/usr/bin/env bash
set -euo pipefail

# Master orchestrator for build -> deploy -> load
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# trap for rollback on error
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

# 1) Basic checks / env load
echo "🔹 [master] Loading .env.local"
export $(grep -v '^#' .env.local | xargs) || true
: "${LOCALSTACK_EDGE_PORT:=4566}"
: "${LAMBDA_DOCKER_NETWORK:=localstack_network}"

# 2) install deps (idempotent)
echo "🔹 [master] Installing node deps (npm install)..."
npm install --legacy-peer-deps

# 3) ensure serverless and awslocal exist
if ! command -v sls &>/dev/null; then
  echo "🔹 [master] Installing Serverless CLI globally..."
  npm install -g serverless
fi
sls --version || true

if ! command -v awslocal &>/dev/null; then
  echo "🔹 [master] Installing awscli-local..."
  if [[ \"$OSTYPE\" == \"darwin\"* ]]; then
    brew install pipx || true
    pipx ensurepath || true
    pipx install awscli-local || true
  else
    python3 -m pip install --user awscli-local || true
  fi
  export PATH=\"$HOME/.local/bin:$PATH\"
fi

echo "🔹 [master] Creating docker network if missing..."
docker network inspect "$LAMBDA_DOCKER_NETWORK" >/dev/null 2>&1 || docker network create "$LAMBDA_DOCKER_NETWORK"

echo "🔹 [master] Starting LocalStack..."
docker-compose up -d

echo "🔹 [master] Waiting for LocalStack STS readiness..."
until docker exec localstack-main awslocal sts get-caller-identity >/dev/null 2>&1; do
  echo "   ⏳ LocalStack not ready, waiting 3s..."
  sleep 3
done

echo "🔹 [master] Ensuring serverless deployment bucket (S3) exists..."
awslocal s3 mb s3://serverlessdeploymentbucket 2>/dev/null || true
sleep 2

# 4) Pre-deploy: create topics and export them in this shell
echo "🔹 [master] Pre-deploy: create topics..."
source scripts/create-topics.sh

# 5) Compile TS
echo "🔹 [master] Compile TypeScript..."
scripts/compile.sh

# 6) Deploy
echo "🔹 [master] Deploying the stack..."
scripts/deploy.sh

# 7) Post-deploy: create queues, subscriptions, sample messages
echo "🔹 [master] Post-deploy: load data..."
source scripts/load-data.sh

API_ID=$(awslocal apigateway get-rest-apis | jq -r '.items[0].id')
echo "✅ System is ready!"
echo "POST /events -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/${API_ID}/events"
echo "POST /recommendations -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/${API_ID}/recommendations"

echo "=== MASTER: Done ==="
