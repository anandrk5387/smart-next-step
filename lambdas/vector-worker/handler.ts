import { SNSEvent } from "aws-lambda";
import { QdrantClient } from "@qdrant/qdrant-js";
import OpenAI from "openai";

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

const qdrantClient = new QdrantClient({
  url: process.env.QDRANT_URL || "http://localhost:6333",
});

// Only initialize OpenAI if API key exists
const openaiApiKey = process.env.OPENAI_API_KEY?.trim();
const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

export const main = async (event: SNSEvent) => {
  const points: QdrantPoint[] = [];

  for (const record of event.Records) {
    try {
      const payload = JSON.parse(record.Sns.Message) as EventMessage;
      if (!payload?.eventId) continue;

      const vector = await generateVector(payload.description ?? "");
      points.push({ id: payload.eventId, vector, payload });
    } catch (err) {
      console.error("VectorWorker: parse error", err);
    }
  }

  if (points.length === 0) return { statusCode: 200 };

  try {
    await qdrantClient.upsert("events_collection", { wait: true, points });
  } catch (err) {
    console.error("VectorWorker: Qdrant upsert failed", err);
  }

  return { statusCode: 200 };
};

async function generateVector(text: string): Promise<number[]> {
  if (openai) {
    try {
      const response = await openai.embeddings.create({
        model: "text-embedding-3-small",
        input: text,
      });
      return response.data[0].embedding;
    } catch (err) {
      console.error("OpenAI embedding failed, using fallback vector", err);
    }
  }

  // Fallback for testing if no API key or OpenAI fails
  return Array(384).fill(0).map(() => Math.random());
}
