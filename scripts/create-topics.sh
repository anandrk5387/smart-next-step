#!/usr/bin/env bash
set -euo pipefail

# Load env
export $(grep -v '^#' .env.local | xargs) || true

# Dynamic topic list
TOPIC_NAMES=("eventTopic" "recommendationTopic" "vectorTopic") 

echo "🔹 [create-topics] Creating SNS topics..."
# Remove old file
TMP_FILE=".topic_arns"
rm -f "$TMP_FILE"

for TOPIC in "${TOPIC_NAMES[@]}"; do
  ARN=$(awslocal sns create-topic --name "$TOPIC" | jq -r '.TopicArn')
  echo "${TOPIC}_ARN=$ARN" >> "$TMP_FILE"
  export "${TOPIC}_ARN=$ARN"
  echo "  ✅ $TOPIC ARN: $ARN"
done

echo "🔹 [create-topics] Topic ARNs saved to $TMP_FILE"
