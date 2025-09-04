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

## ⚠️ Assessment Gap Report

Due to time constraints, the following areas are either partially implemented or left as known limitations:  

- **OpenAI Integration** → Vector embeddings currently use a fallback (random vectors). Direct integration with OpenAI was planned but not finalized.  
- **Error Handling & Retries** → External service calls (Qdrant, DynamoDB, SNS) have minimal retry or backoff logic; no dead-letter queues configured.  
- **Recommendations API** → Endpoint is stubbed/mocked; does not yet return real recommendation results.  
- **Testing Coverage** → Integration tests verify core flows but lack edge cases, load testing, and full negative-path validation.  
- **Documentation** → Architecture and event flow covered, but deeper deployment notes, troubleshooting, and design trade-offs are limited.  
- **Observability** → Logging is basic; no structured monitoring, metrics, or centralized tracing.  
- **Secrets Management** → API keys (e.g., OpenAI) are stored in environment variables only; no secure rotation/management strategy applied.  

## 🚀 Actual Improvements Needed

Based on the identified gaps, the following improvements are recommended:  

- **Enable OpenAI Embeddings** → Replace random vector generation with OpenAI’s embedding API for realistic recommendation workflows.  
- **Enhance Reliability** → Add retry/backoff strategies, DLQs for SNS-triggered Lambdas, and transaction safeguards in DynamoDB/Qdrant operations.  
- **Implement Real Recommendations** → Build out the `/recommendations` endpoint to query Qdrant for nearest-neighbor search and return ranked results.  
- **Expand Testing** → Add negative-path, stress/load tests, and automated regression tests to improve coverage.  
- **Strengthen Documentation** → Include deployment steps (CloudFormation/Terraform), troubleshooting tips, and detailed design decisions.  
- **Improve Observability** → Introduce structured logging, CloudWatch metrics, and distributed tracing for better debugging.  
- **Secure Secrets Management** → Move sensitive keys to AWS Secrets Manager or Parameter Store with rotation policies.  
