#!/usr/bin/env bash
set -euo pipefail

# Create SNS topics before Serverless deploy so ${env:EVENT_TOPIC_ARN} resolves.
echo "🔹 [create-topics] Loading environment variables..."
export $(grep -v '^#' .env.local | xargs) || true

: "${LOCALSTACK_EDGE_PORT:=4566}"

echo "🔹 [create-topics] Ensuring awslocal available..."
if ! command -v awslocal &>/dev/null; then
  echo "  awslocal not found. Please install awscli-local (pipx install awscli-local) or add to PATH."
  exit 1
fi

echo "🔹 [create-topics] Creating SNS topics (idempotent)..."
export EVENT_TOPIC_ARN=$(awslocal sns create-topic --name eventTopic | jq -r '.TopicArn')
export RECOMMEND_TOPIC_ARN=$(awslocal sns create-topic --name recommendationTopic | jq -r '.TopicArn')

echo "  EVENT_TOPIC_ARN=$EVENT_TOPIC_ARN"
echo "  RECOMMEND_TOPIC_ARN=$RECOMMEND_TOPIC_ARN"

# Export to shell environment for callers that source this script
export EVENT_TOPIC_ARN RECOMMEND_TOPIC_ARN
echo "🔹 [create-topics] Done."