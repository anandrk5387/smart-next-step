#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [deploy] Loading environment..."
export $(grep -v '^#' .env.local | xargs) || true
: "${LOCALSTACK_EDGE_PORT:=4566}"

# Load topic ARNs from .topic_arns
if [[ ! -f .topic_arns ]]; then
  echo "❗ .topic_arns not found. Run create-topics.sh first."
  exit 1
fi
export $(grep -v '^#' .topic_arns | xargs)

echo "🔹 [deploy] Deploying Serverless to LocalStack..."

# Prepare env list for Serverless
ENV_VARS="LOCALSTACK_EDGE_PORT=$LOCALSTACK_EDGE_PORT"
for VAR in $(grep '=' .topic_arns | cut -d= -f1); do
  ENV_VARS="$ENV_VARS $VAR=${!VAR}"
done

# Load topics dynamically from .topic_arns
TOPICS_JSON=$(jq -n '{eventTopic_ARN: env.eventTopic_ARN, recommendationTopic_ARN: env.recommendationTopic_ARN}')
export TOPICS_JSON

# Deploy
eval $ENV_VARS npx serverless deploy --stage dev

echo "🔹 [deploy] Deployment complete."
