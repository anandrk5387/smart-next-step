# smart-next-step
A "Smart Next-Step" recommendation system — an AI-powered service that analyses customer behaviour patterns and recommends the most likely next legal or accounting action

## Assessment Time Tracking

| Date       | Task / Activity                                  | Hours Spent |
|------------|-------------------------------------------------|------------|
| 2025-08-30 | Initial project setup, Serverless config review | 2.5          |
| 2025-08-31 | Lambda function implementation, vectorWorker   | 2          |
| 2025-09-01 | Deployment scripts, LocalStack testing         | 3          |
| 2025-09-03 | Qdrant integration, embeddings, fallback logic | 3          |
| 2025-09-04 | README, architecture & decisions documentation | 2          |
| **Total**  |                                                 | **12.5**     |


## AI Assistance

During this assessment, AI tools ChatGPT/CoPilot were used to:

- Draft initial Serverless configuration and deployment scripts.
- Design and document architecture and technical decisions.
- Generate basic Lambda code scaffolding for vector embeddings and event handling.
- Draft README, Mermaid diagrams, and markdown documentation.

**Extent of AI usage:**  
- Approximately 50 - 60%% of code snippets and documentation were AI-assisted.  
- All core logic, integration testing, and debugging were performed manually.  
- AI was used as a helper for structure, formatting, and boilerplate generation only.

## Running & Testing the Assessment

### 1. Prerequisites

- **Node.js** >= 18  
- **Docker** (for LocalStack and Qdrant)  
- **AWS CLI / awslocal** (LocalStack CLI)  
- Optional: `OPENAI_API_KEY` (for real embeddings; fallback is included)

### 2. Clone & Setup

```bash
git clone <repo-url>
cd smart-next-step
scripts/setup.sh
```
**Edit .env.local to add OPENAI_API_KEY if available**  

### 3. Verify Deployment

**Check Lambda containers are running:**  
```bash
docker ps | grep localstack
```

**List SNS subscriptions:**  
```bash
awslocal sns list-subscriptions
```

**Verify DynamoDB table:**  
```bash
awslocal dynamodb list-tables
```

### 4. Run Tests

```bash
scripts/test.sh
```