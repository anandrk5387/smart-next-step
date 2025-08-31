#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [cleanup] Removing Serverless stack (CloudFormation) from LocalStack..."
if command -v npx &>/dev/null; then
  # best-effort remove - ignore errors
  npx serverless remove --stage dev || true
fi

echo "🔹 [cleanup] Deleting SNS topics (if exist)..."
awslocal sns list-topics | jq -r '.Topics[].TopicArn' 2>/dev/null | while read -r arn; do
  echo "  Deleting $arn"
  awslocal sns delete-topic --topic-arn "$arn" || true
done || true

echo "🔹 [cleanup] Deleting SQS queues (if exist)..."
awslocal sqs list-queues | jq -r '.QueueUrls[]' 2>/dev/null | while read -r url; do
  echo "  Deleting $url"
  awslocal sqs delete-queue --queue-url "$url" || true
done || true

echo "🔹 [cleanup] Removing local build artifacts (dist, .serverless) ..."
rm -rf dist .serverless || true

echo "✅ [cleanup] Done."
