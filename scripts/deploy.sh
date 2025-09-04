#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [deploy] Loading environment..."
export $(grep -v '^#' .env.local | xargs) || true
: "${LOCALSTACK_EDGE_PORT:=4566}"

# Load topic ARNs from .topic_arns if exists
if [[ -f .topic_arns ]]; then
  export $(grep -v '^#' .topic_arns | xargs) || true
fi

# ----------------------------
# Step 1: Clean old Lambda containers
# ----------------------------
echo "🔹 [deploy] Cleaning old LocalStack Lambda containers..."
docker ps -a | grep localstack-main-lambda | awk '{print $1}' | xargs -r docker rm -f || true

# ----------------------------
# Step 2: Unsubscribe old SNS subscriptions
# ----------------------------
echo "🔹 [deploy] Removing old SNS subscriptions..."
SUBS=$(awslocal sns list-subscriptions | jq -r '.Subscriptions[].SubscriptionArn')
if [[ -n "$SUBS" ]]; then
  echo "$SUBS" | xargs -r -n1 awslocal sns unsubscribe
fi

# ----------------------------
# Step 3: Deploy Serverless stack (auto-create resources)
# ----------------------------
echo "🔹 [deploy] Deploying Serverless stack..."
ENV_VARS="LOCALSTACK_EDGE_PORT=$LOCALSTACK_EDGE_PORT"
eval $ENV_VARS npx serverless deploy --stage dev || {
    echo "❗ Serverless deploy failed. Exiting."
    exit 1
}

# ----------------------------
# Step 4: Subscribe Lambda workers to SNS topics
# ----------------------------
echo "🔹 [deploy] Subscribing Lambda functions to SNS topics..."
WORKERS=("vectorWorker" "dynamoWorker")

for LAMBDA in "${WORKERS[@]}"; do
  SUB=$(awslocal sns list-subscriptions | jq -r ".Subscriptions[] | select(.Endpoint==\"arn:aws:lambda:ap-southeast-2:000000000000:function:smart-next-step-dev-$LAMBDA\") | .SubscriptionArn")
  if [[ -z "$SUB" ]]; then
    echo "  ⚡ Subscribing $LAMBDA to eventTopic..."
    awslocal sns subscribe \
      --topic-arn "$eventTopic_ARN" \
      --protocol lambda \
      --notification-endpoint "arn:aws:lambda:ap-southeast-2:000000000000:function:smart-next-step-dev-$LAMBDA"
  else
    echo "  ✅ $LAMBDA already subscribed."
  fi
done

echo "🔹 [deploy] Deployment complete. Only one container per worker exists now."
