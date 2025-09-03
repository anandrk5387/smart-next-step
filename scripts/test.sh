#!/usr/bin/env bash
set -euo pipefail

echo "=== Running Integration Tests ==="

# Load environment
export $(grep -v '^#' .env.local | xargs) || true

# Get API Gateway ID dynamically from LocalStack
API_ID=$(awslocal apigateway get-rest-apis --query 'items[0].id' --output text 2>/dev/null || echo "")
if [[ -z "$API_ID" ]]; then
  echo "❌ Could not find API Gateway in LocalStack"
  exit 1
fi
export API_ID

# Run test runner
npx ts-node scripts/test-runner.ts
