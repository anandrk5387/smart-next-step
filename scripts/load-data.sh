#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [load-data] Loading environment variables..."
export $(grep -v '^#' .env.local | xargs) || true

if [[ -z "${EVENT_TOPIC_ARN:-}" || -z "${RECOMMEND_TOPIC_ARN:-}" ]]; then
  echo "❗ EVENT_TOPIC_ARN / RECOMMEND_TOPIC_ARN not set. Please source create-topics.sh or re-run deploy."
  exit 1
fi

echo "🔹 [load-data] Creating SQS queues..."
EVENT_QUEUE_URL=$(awslocal sqs create-queue --queue-name eventQueue | jq -r '.QueueUrl')
RECOMMEND_QUEUE_URL=$(awslocal sqs create-queue --queue-name recommendationQueue | jq -r '.QueueUrl')

echo "  Event Queue URL: $EVENT_QUEUE_URL"
echo "  Recommendation Queue URL: $RECOMMEND_QUEUE_URL"

# Get ARNs
EVENT_QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$EVENT_QUEUE_URL" --attribute-names QueueArn | jq -r '.Attributes.QueueArn')
RECOMMEND_QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$RECOMMEND_QUEUE_URL" --attribute-names QueueArn | jq -r '.Attributes.QueueArn')

echo "  Event Queue ARN: $EVENT_QUEUE_ARN"
echo "  Recommendation Queue ARN: $RECOMMEND_QUEUE_ARN"

# Apply queue policies (idempotent)
EVENT_POLICY_JSON="{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":\\\"*\\\",\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$EVENT_QUEUE_ARN\\\"}]}\"}"
RECOMMEND_POLICY_JSON="{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":\\\"*\\\",\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$RECOMMEND_QUEUE_ARN\\\"}]}\"}"

awslocal sqs set-queue-attributes --queue-url "$EVENT_QUEUE_URL" --attributes "$EVENT_POLICY_JSON" >/dev/null
awslocal sqs set-queue-attributes --queue-url "$RECOMMEND_QUEUE_URL" --attributes "$RECOMMEND_POLICY_JSON" >/dev/null

echo "🔹 [load-data] Subscribing queues to topics..."
awslocal sns subscribe --topic-arn "$EVENT_TOPIC_ARN" --protocol sqs --notification-endpoint "$EVENT_QUEUE_ARN" >/dev/null
awslocal sns subscribe --topic-arn "$RECOMMEND_TOPIC_ARN" --protocol sqs --notification-endpoint "$RECOMMEND_QUEUE_ARN" >/dev/null

echo "🔹 [load-data] Publishing sample messages..."
awslocal sns publish --topic-arn "$EVENT_TOPIC_ARN" --message '{"userId":"user1","event":"login"}' >/dev/null
awslocal sns publish --topic-arn "$RECOMMEND_TOPIC_ARN" --message '{"userId":"user1","recommendation":"product123"}' >/dev/null

echo "✅ [load-data] Sample data loaded."