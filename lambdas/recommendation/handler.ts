import { QdrantClient } from "@qdrant/qdrant-js";

interface RecommendationRequest {
  userId: string;
  limit?: number;
}

export const main = async (event: any) => {
  const client = new QdrantClient({
    url: process.env.QDRANT_URL!,
  });

  const query: RecommendationRequest = event.queryStringParameters || {};
  const userId = query.userId;
  const limit = Number(query.limit) || 5;

  // Example: retrieve vector embedding for user's latest event from DynamoDB
  const userVector = getUserVector(userId); // Implement this

  const searchResult = await client.search(
    "events_collection", // your Qdrant collection name
    {
      vector: userVector,
      limit,
    }
  );

  const recommendations = searchResult.map((r: any) => ({
    eventId: r.id,
    score: r.score,
    payload: r.payload,
  }));

  return {
    statusCode: 200,
    body: JSON.stringify(recommendations),
  };
};

// Dummy placeholder
function getUserVector(userId: string) {
  return Array(384).fill(0); // Replace with actual embedding retrieval
}
