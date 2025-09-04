#!/usr/bin/env bash
set -euo pipefail

echo "=== Waiting for LocalStack APIs and Lambdas ==="

# Load environment
export $(grep -v '^#' .env.local | xargs) || true

LOCALSTACK_HOST=${LOCALSTACK_HOST:-localhost}
EDGE_PORT=${LOCALSTACK_EDGE_PORT:-4566}

MAX_RETRIES=10
SLEEP_TIME=3

# Helper to check if Lambda is ready
check_lambda_ready() {
  local function_name=$1
  local ready=$(awslocal lambda list-functions --query "Functions[?FunctionName=='$function_name'].FunctionName" --output text)
  [[ "$ready" == "$function_name" ]]
}

# Wait until all Lambdas are created
LAMBDA_NAMES=(
  "smart-next-step-dev-eventIngestion"
  "smart-next-step-dev-recommendation"
  "smart-next-step-dev-vectorWorker"
  "smart-next-step-dev-dynamoWorker"
)

for lambda in "${LAMBDA_NAMES[@]}"; do
  retries=0
  until check_lambda_ready "$lambda"; do
    ((retries++))
    if [ "$retries" -ge "$MAX_RETRIES" ]; then
      echo "❌ Lambda $lambda not ready after $((MAX_RETRIES * SLEEP_TIME))s"
      exit 1
    fi
    echo "⏳ Waiting for Lambda $lambda to be ready... ($retries/$MAX_RETRIES)"
    sleep $SLEEP_TIME
  done
  echo "✅ Lambda $lambda is ready"
done

# Get API Gateway ID dynamically from LocalStack
API_ID=$(awslocal apigateway get-rest-apis --query 'items[0].id' --output text 2>/dev/null || echo "")
if [[ -z "$API_ID" ]]; then
  echo "❌ Could not find API Gateway in LocalStack"
  exit 1
fi
export API_ID

echo "=== Running Integration Tests ==="
npx ts-node scripts/test-runner.ts
