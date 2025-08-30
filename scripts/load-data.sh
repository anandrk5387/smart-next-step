#!/bin/bash
set -e

echo "🔹 Loading environment variables..."
export $(grep -v '^#' .env.local | xargs)

# Create SNS topics
echo "🔹 Creating SNS topics..."
EVENT_TOPIC_ARN=$(awslocal sns create-topic --name eventTopic | jq -r '.TopicArn')
RECOMMEND_TOPIC_ARN=$(awslocal sns create-topic --name recommendationTopic | jq -r '.TopicArn')
echo "Event Topic ARN: $EVENT_TOPIC_ARN"
echo "Recommendation Topic ARN: $RECOMMEND_TOPIC_ARN"

# Create SQS queues
echo "🔹 Creating SQS queues..."
EVENT_QUEUE_URL=$(awslocal sqs create-queue --queue-name eventQueue | jq -r '.QueueUrl')
RECOMMEND_QUEUE_URL=$(awslocal sqs create-queue --queue-name recommendationQueue | jq -r '.QueueUrl')
echo "Event Queue URL: $EVENT_QUEUE_URL"
echo "Recommendation Queue URL: $RECOMMEND_QUEUE_URL"

# Get queue ARNs
EVENT_QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$EVENT_QUEUE_URL" --attribute-names QueueArn | jq -r '.Attributes.QueueArn')
RECOMMEND_QUEUE_ARN=$(awslocal sqs get-queue-attributes --queue-url "$RECOMMEND_QUEUE_URL" --attribute-names QueueArn | jq -r '.Attributes.QueueArn')
echo "Event Queue ARN: $EVENT_QUEUE_ARN"
echo "Recommendation Queue ARN: $RECOMMEND_QUEUE_ARN"

# Set Event Queue policy
# Event queue policy
EVENT_POLICY_JSON="{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":\\\"*\\\",\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$EVENT_QUEUE_ARN\\\"}]}\"}"

# Recommendation queue policy
RECOMMEND_POLICY_JSON="{\"Policy\":\"{\\\"Version\\\":\\\"2012-10-17\\\",\\\"Statement\\\":[{\\\"Effect\\\":\\\"Allow\\\",\\\"Principal\\\":\\\"*\\\",\\\"Action\\\":\\\"sqs:SendMessage\\\",\\\"Resource\\\":\\\"$RECOMMEND_QUEUE_ARN\\\"}]}\"}"

# Apply attributes
awslocal sqs set-queue-attributes --queue-url "$EVENT_QUEUE_URL" --attributes "$EVENT_POLICY_JSON"
awslocal sqs set-queue-attributes --queue-url "$RECOMMEND_QUEUE_URL" --attributes "$RECOMMEND_POLICY_JSON"


# Subscribe queues to topics
echo "🔹 Subscribing SQS queues to SNS topics..."
awslocal sns subscribe --topic-arn "$EVENT_TOPIC_ARN" --protocol sqs --notification-endpoint "$EVENT_QUEUE_ARN"
awslocal sns subscribe --topic-arn "$RECOMMEND_TOPIC_ARN" --protocol sqs --notification-endpoint "$RECOMMEND_QUEUE_ARN"

# Publish sample messages
echo "🔹 Publishing sample messages..."
awslocal sns publish --topic-arn "$EVENT_TOPIC_ARN" --message '{"userId": "user1", "event": "login"}'
awslocal sns publish --topic-arn "$RECOMMEND_TOPIC_ARN" --message '{"userId": "user1", "recommendation": "product123"}'

echo "✅ Sample data loaded successfully!"
