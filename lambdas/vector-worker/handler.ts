import { SNSEvent } from "aws-lambda";
import { QdrantClient } from "@qdrant/qdrant-js";

// Minimal shape Qdrant accepts for upsert()
type QdrantPoint = {
  id: string | number;
  vector: number[];
  payload?: Record<string, unknown>;
};

type EventMessage = {
  companyId: string;
  userId: string;
  eventType: string;
  description?: string;
  metadata?: Record<string, unknown>;
  eventId: string;
  timestamp: string;
};

export const main = async (event: SNSEvent) => {
  const qdrantUrl = process.env.QDRANT_URL || "http://localhost:6333";
  const client = new QdrantClient({ url: qdrantUrl });

  const points: QdrantPoint[] = event.Records
    .map((record) => {
      try {
        const payload = JSON.parse(record.Sns.Message) as EventMessage;
        if (!payload?.eventId) return null;

        const vector = generateVector(payload.description ?? "");
        return {
          id: payload.eventId,
          vector,
          payload,
        } as QdrantPoint;
      } catch (err) {
        console.error("VectorWorker: parse error", err);
        return null;
      }
    })
    .filter((p): p is QdrantPoint => p !== null); // type guard removes nulls

  if (points.length === 0) return { statusCode: 200 };

  try {
    await client.upsert("events_collection", {
      wait: true,
      points,
    });
  } catch (err) {
    console.error("VectorWorker: Qdrant upsert failed", err);
  }

  return { statusCode: 200 };
};

function generateVector(text: string): number[] {
  // TODO: replace with real embeddings
  return Array(384).fill(0).map(() => Math.random());
}
