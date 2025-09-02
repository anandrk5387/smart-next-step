import { QdrantClient } from "@qdrant/qdrant-js";

export const main = async (event: any) => {
  const client = new QdrantClient({
    url: process.env.QDRANT_URL!,
  });

  // Extract messages from SNS event
  const records = event.Records || [];
  for (const record of records) {
    const payload = JSON.parse(record.Sns.Message);

    const vector: number[] = generateVector(payload.description); // Implement embedding

    await client.upsert("events_collection", {
      wait: true,
      points: [
        {
          id: payload.eventId,
          vector,
          payload,
        },
      ],
    });

  }

  return { statusCode: 200 };
};

// Dummy placeholder
function generateVector(text: string): number[] {
  return Array(384).fill(Math.random()); // Replace with actual embedding logic
}
