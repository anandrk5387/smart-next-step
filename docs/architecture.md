# System Architecture

## Overview
The `smart-next-step` service is a serverless event-driven application built using AWS services, with LocalStack used for local testing. It ingests user events, processes them, and stores vector embeddings for recommendation workflows.

## Components

### 1. Lambda Functions
- **eventIngestion**
  - Receives HTTP POST requests at `/events`.
  - Publishes messages to `eventTopic` SNS.
  
- **recommendation**
  - Receives HTTP GET requests at `/recommendations`.
  - Fetches recommendations based on processed events.

- **vectorWorker**
  - Subscribed to `eventTopic` SNS.
  - Generates vector embeddings (via OpenAI or fallback random vectors).
  - Upserts embeddings into Qdrant collection `events_collection`.

- **dynamoWorker**
  - Subscribed to `eventTopic` SNS.
  - Persists event metadata into `EventTable` (DynamoDB).

### 2. AWS Services
- **SNS Topics**
  - `eventTopic` → triggers vectorWorker & dynamoWorker.
  - `recommendationTopic` → optional downstream recommendation triggers.
  - `vectorTopic` → optional SQS integration for vector processing.

- **DynamoDB**
  - `EventTable` stores events keyed by `companyId` and `eventId`.

- **Qdrant**
  - Stores vector embeddings for event descriptions for fast similarity search.

### 3. LocalStack
- Simulates AWS services locally for testing.
- Configured to reuse Lambda containers to reduce startup overhead.
- Handles cleanup of old containers automatically.

## Event Flow

```mermaid
sequenceDiagram
    participant Client
    participant EventIngestion
    participant SNS as eventTopic
    participant VectorWorker
    participant DynamoWorker
    participant Qdrant
    participant DynamoDB as EventTable

    Client->>EventIngestion: POST /events
    EventIngestion->>SNS: Publish event message
    SNS->>VectorWorker: Trigger Lambda
    SNS->>DynamoWorker: Trigger Lambda
    VectorWorker->>Qdrant: Upsert vector embedding
    DynamoWorker->>DynamoDB: Store event metadata
