# Technical Decisions

## 1. Serverless + LocalStack
- **Reason:** Enables AWS-native serverless development and testing locally without incurring cloud costs.
- **Benefit:** Rapid iteration, easy testing of SNS, Lambda, and DynamoDB locally.

## 2. Lambda Container Management
- **Reuse Containers:** Enabled to speed up repeated function invocations.
- **Fallback Random Vectors:** Prevents failures if OpenAI API key is missing.

## 3. Event-driven Design
- **SNS topics** decouple ingestion from processing.
- Multiple subscribers (`vectorWorker`, `dynamoWorker`) handle different responsibilities independently.
- Prevents tight coupling between event ingestion and downstream processing.

## 4. Vector Embeddings
- **OpenAI Embeddings:** Used to generate semantic vectors from event descriptions.
- **Fallback:** Random vectors for testing/assessment when `OPENAI_API_KEY` is absent.
- **Reason:** Ensures assessment team can test the system without needing a valid OpenAI key.

## 5. Qdrant for Vector Storage
- **Reason:** Provides fast, scalable similarity search.
- **Benefit:** Supports recommendation engine and vector-based queries.

## 6. DynamoDB
- Chosen for serverless, schema-less storage of event metadata.
- PAY_PER_REQUEST billing mode reduces cost during local testing.

## 7. Cleanup & Subscription Management
- Deploy scripts automatically remove old Lambda containers and duplicate SNS subscriptions.
- Prevents resource duplication during repeated deployments.

