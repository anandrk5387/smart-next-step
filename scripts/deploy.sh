#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [deploy] Loading env from .env.local..."
export $(grep -v '^#' .env.local | xargs) || true

# Expect EVENT_TOPIC_ARN and RECOMMEND_TOPIC_ARN set (from create-topics.sh)
if [[ -z "${EVENT_TOPIC_ARN:-}" || -z "${RECOMMEND_TOPIC_ARN:-}" ]]; then
  echo "❗ EVENT_TOPIC_ARN or RECOMMEND_TOPIC_ARN not set. Source create-topics.sh first."
  exit 1
fi

: "${LOCALSTACK_EDGE_PORT:=4566}"

echo "🔹 [deploy] Deploying Serverless to LocalStack..."
# Pass env inline so Serverless resolves ${env:EVENT_TOPIC_ARN} during deploy
LOCALSTACK_EDGE_PORT="$LOCALSTACK_EDGE_PORT" \
EVENT_TOPIC_ARN="$EVENT_TOPIC_ARN" \
RECOMMEND_TOPIC_ARN="$RECOMMEND_TOPIC_ARN" \
npx serverless deploy --stage dev

echo "🔹 [deploy] Deploy complete."
