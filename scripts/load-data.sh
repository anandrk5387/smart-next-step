#!/usr/bin/env bash
set -euo pipefail

# Load env and topic ARNs
export $(grep -v '^#' .env.local | xargs) || true
: "${LOCALSTACK_EDGE_PORT:=4566}"

if [[ ! -f .topic_arns ]]; then
  echo "❗ Topic ARNs file not found. Run create-topics.sh first."
  exit 1
fi
export $(grep -v '^#' .topic_arns | xargs)

echo "🔹 [load-data] Creating SQS queues and subscribing to SNS topics..."

for TOPIC_VAR in $(grep '=' .topic_arns | cut -d= -f1); do
  TOPIC_ARN=${!TOPIC_VAR}
  QUEUE_NAME="${TOPIC_VAR/Topic/Queue}"
  
  QUEUE_URL=$(awslocal sqs create-queue --queue-name "$QUEUE_NAME" | jq -r '.QueueUrl')
  QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names QueueArn | jq -r '.Attributes.QueueArn')
  
  POLICY_JSON="{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":\\\"*\\\",\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$QUEUE_ARN\\\"}]}\"}"
  awslocal sqs set-queue-attributes --queue-url "$QUEUE_URL" --attributes "$POLICY_JSON"

  awslocal sns subscribe --topic-arn "$TOPIC_ARN" --protocol sqs --notification-endpoint "$QUEUE_ARN"
  echo "  ✅ $QUEUE_NAME subscribed to $TOPIC_VAR"
done

# Publish sample events
DATA_FILE="data/sample-events.json"
if [[ -f "$DATA_FILE" ]]; then
  echo "🔹 [load-data] Publishing sample events from $DATA_FILE..."
  while IFS= read -r EVENT; do
    awslocal sns publish --topic-arn "$eventTopic_ARN" --message "$EVENT"
  done < <(jq -c '.[]' "$DATA_FILE")
  echo "✅ Sample events loaded."
else
  echo "⚠️ Sample events file $DATA_FILE not found. Skipping."
fi
