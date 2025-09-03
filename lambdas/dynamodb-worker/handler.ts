import { SNSEvent } from "aws-lambda";
import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

type EventMessage = {
  companyId: string;
  userId: string;
  eventType: string;
  description?: string;
  metadata?: Record<string, unknown>;
  eventId: string;
  timestamp: string;
};

const REGION = process.env.AWS_REGION || "ap-southeast-2";
const TABLE_NAME = process.env.EVENTS_TABLE || "EventTable";

const db = new DynamoDBClient({
  region: REGION,
  // If you ever need an explicit LocalStack endpoint inside Lambda:
  // endpoint: process.env.AWS_ENDPOINT_URL || `http://${process.env.LOCALSTACK_HOSTNAME || "localhost"}:${process.env.LOCALSTACK_EDGE_PORT || "4566"}`
});

export const main = async (event: SNSEvent) => {
  const tasks = event.Records.map(async (record) => {
    try {
      const payload = JSON.parse(record.Sns.Message) as EventMessage;
      if (!payload.companyId || !payload.eventId) return;

      await db.send(
        new PutItemCommand({
          TableName: TABLE_NAME,
          Item: {
            companyId: { S: payload.companyId },
            eventId: { S: payload.eventId },
            userId: { S: payload.userId },
            eventType: { S: payload.eventType },
            timestamp: { S: payload.timestamp },
            description: { S: payload.description ?? "" },
            metadata: { S: JSON.stringify(payload.metadata ?? {}) },
          },
          // ReturnConsumedCapacity: "TOTAL", // uncomment if you want to see capacity
        })
      );
    } catch (err) {
      console.error("DynamoWorker: failed to handle record", err);
    }
  });

  await Promise.allSettled(tasks);
  return { statusCode: 200 };
};
