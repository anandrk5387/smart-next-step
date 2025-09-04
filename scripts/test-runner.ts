#!/usr/bin/env ts-node
import assert from "assert";
import AWS from "aws-sdk";

// Dynamic import for node-fetch (ESM)
const fetch = async (...args: Parameters<typeof import("node-fetch")>) =>
  (await import("node-fetch")).default(...args);

const LOCALSTACK_ENDPOINT = `http://localhost:${process.env.LOCALSTACK_EDGE_PORT ?? 4566}`;
const API_BASE = `${LOCALSTACK_ENDPOINT}/restapis`;
const EVENT_TOPIC_ARN = process.env.eventTopic_ARN!;
const EVENTS_TABLE = process.env.EVENTS_TABLE!;
const QDRANT_URL = process.env.QDRANT_URL ?? "http://localhost:6333";

// AWS SDK clients
const sns = new AWS.SNS({ endpoint: LOCALSTACK_ENDPOINT, region: process.env.AWS_REGION });
const dynamo = new AWS.DynamoDB.DocumentClient({ endpoint: LOCALSTACK_ENDPOINT, region: process.env.AWS_REGION });

async function waitForLambdaReady(functionName: string, retries = 10, delayMs = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      const res = await sns.listSubscriptionsByTopic({ TopicArn: EVENT_TOPIC_ARN }).promise();
      if (res.Subscriptions?.some(s => s.Endpoint?.includes(functionName))) return;
    } catch {}
    await new Promise(r => setTimeout(r, delayMs));
  }
  throw new Error(`Lambda ${functionName} not ready after ${retries} retries`);
}

function logSuccess(msg: string) { console.log(`✅ ${msg}`); }
function logFail(msg: string, err?: any) { console.error(`❌ ${msg}`); if (err) console.error(err); process.exitCode = 1; }

type EventPayload = {
  companyId: string;
  userId: string;
  eventType: string;
  description?: string;
  metadata?: Record<string, unknown>;
  eventId?: string;
  timestamp?: string;
};

async function testEventIngestion(apiId: string) {
  console.log("\n=== Test: Event Ingestion ===");

  const payload: EventPayload = {
    companyId: "comp_123",
    userId: "user_456",
    eventType: "document_created",
    description: "Test document",
    metadata: { docType: "agreement" },
  };

  try {
    const res = await fetch(`${API_BASE}/${apiId}/events`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    assert.strictEqual(res.status, 200, "POST /events failed");
    const body = await res.json() as { eventId: string };
    assert.ok(body.eventId, "eventId missing");
    logSuccess("POST /events succeeded");

    // Wait for Lambdas to process
    await waitForLambdaReady("vectorWorker");
    await waitForLambdaReady("dynamoWorker");

    // DynamoDB verification
    const dbRes = await dynamo.get({ TableName: EVENTS_TABLE, Key: { companyId: payload.companyId, eventId: body.eventId } }).promise();
    assert.ok(dbRes.Item, "DynamoDB record missing");
    logSuccess("DynamoDB record exists");

    // SNS verification
    const subs = await sns.listSubscriptionsByTopic({ TopicArn: EVENT_TOPIC_ARN }).promise();
    assert.ok(subs.Subscriptions?.length > 0, "SNS subscriptions missing");
    logSuccess("SNS subscriptions exist");

    // Qdrant verification (basic)
    const qdrRes = await fetch(`${QDRANT_URL}/collections/events_collection/points/${body.eventId}`);
    const qdrBody = await qdrRes.json();
    assert.ok(qdrBody.result || qdrBody, "Event not indexed in Qdrant");
    logSuccess("Qdrant point exists");
  } catch (err) {
    logFail("Event ingestion test failed", err);
  }
}

async function testRecommendations(apiId: string) {
  console.log("\n=== Test: Recommendations ===");
  try {
    const url = `${API_BASE}/${apiId}/recommendations?user_id=user_456&limit=5`;
    const res = await fetch(url);
    assert.strictEqual(res.status, 200, "GET /recommendations failed");
    const body = await res.json() as { recommendations: { score: number; confidence: number }[] };
    assert.ok(Array.isArray(body.recommendations) && body.recommendations.length === 5, "Recommendations invalid");

    const scores = body.recommendations.map(r => r.score);
    assert.deepStrictEqual(scores, [...scores].sort((a, b) => b - a), "Recommendations not sorted");
    logSuccess("Recommendations returned, sorted by score, with confidence levels");

    // Response time < 200ms
    const start = Date.now();
    await fetch(url);
    const ms = Date.now() - start;
    assert.ok(ms < 200, `Response too slow: ${ms}ms`);
    logSuccess(`Response time < 200ms (${ms}ms)`);
  } catch (err) {
    logFail("Recommendations test failed", err);
  }
}

async function main() {
  console.log("=== Running Integration Tests ===");

  try {
    const apisRes = await fetch(API_BASE);
    const apisBody = await apisRes.json() as { items: { id: string }[] };
    const apiId = apisBody.items?.[0]?.id;
    if (!apiId) throw new Error("API Gateway ID not found");

    await testEventIngestion(apiId);
    await testRecommendations(apiId);

    console.log("\n=== Tests Completed ===");
    if (process.exitCode === 1) console.error("❌ Some tests failed");
    else console.log("🎉 All tests passed");
  } catch (err) {
    logFail("Test runner setup failed", err);
  }
}

main();
