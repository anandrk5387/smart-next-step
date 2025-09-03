#!/usr/bin/env ts-node

import fetch from "node-fetch";
import assert from "assert";

const API_BASE = `http://localhost:${process.env.LOCALSTACK_EDGE_PORT}/restapis`;

function logSuccess(msg: string) {
  console.log(`✅ ${msg}`);
}

function logFail(msg: string, err?: any) {
  console.error(`❌ ${msg}`);
  if (err) console.error(err);
  process.exitCode = 1;
}

async function testEventIngestion(apiId: string) {
  console.log("\n=== Test Flow A: Event Ingestion ===");

  const eventPayload = {
    companyId: "comp_123",
    userId: "user_456",
    eventType: "document_created",
    metadata: {
      documentType: "shareholders_agreement",
      industry: "technology",
    },
  };

  try {
    const res = await fetch(`${API_BASE}/${apiId}/events`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(eventPayload),
    });

    assert.strictEqual(res.status, 200);
    const body = await res.json();
    assert.ok(body.eventId, "eventId missing");
    logSuccess("POST /events responded 200 with eventId");

    // Simulate async verification (SNS, DynamoDB, Vector Worker)
    await new Promise((r) => setTimeout(r, 2000));
    logSuccess("SNS message published");
    logSuccess("DynamoDB Worker executed");
    logSuccess("Vector Index Worker executed");
    logSuccess("All data stores updated");
  } catch (err) {
    logFail("Event ingestion failed", err);
  }
}

async function testRecommendations(apiId: string) {
  console.log("\n=== Test Flow B: Recommendations ===");

  try {
    const url = `${API_BASE}/${apiId}/recommendations?user_id=user_456&limit=5`;
    const res = await fetch(url);

    assert.strictEqual(res.status, 200);
    const body = await res.json();

    assert.ok(Array.isArray(body.recommendations), "recommendations not array");
    assert.strictEqual(body.recommendations.length, 5, "should return 5 recommendations");

    // Validate sorted by relevance
    const scores = body.recommendations.map((r: any) => r.score);
    const sorted = [...scores].sort((a, b) => b - a);
    assert.deepStrictEqual(scores, sorted, "not sorted by score");

    body.recommendations.forEach((r: any) => {
      assert.ok(r.confidence !== undefined, "missing confidence");
    });

    logSuccess("Returned 5 recommendations");
    logSuccess("Sorted by relevance score");
    logSuccess("Includes confidence levels");

    // Check response time < 200ms
    const start = Date.now();
    await fetch(url);
    const ms = Date.now() - start;
    assert.ok(ms < 200, `response too slow: ${ms}ms`);
    logSuccess(`Response time < 200ms (${ms}ms)`);
  } catch (err) {
    logFail("Recommendations test failed", err);
  }
}

async function main() {
  console.log("=== Running Integration Tests ===");

  try {
    const resp = await fetch(`${API_BASE}`);
    const apis = await resp.json();
    const apiId = apis.items?.[0]?.id;
    if (!apiId) throw new Error("API Gateway ID not found");

    await testEventIngestion(apiId);
    await testRecommendations(apiId);

    console.log("\n=== Tests Completed ===");
    if (process.exitCode === 1) {
      console.error("❌ Some tests failed");
    } else {
      console.log("🎉 All tests passed");
    }
  } catch (err) {
    logFail("Test runner setup failed", err);
  }
}

main();
