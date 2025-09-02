import { DynamoDBClient, PutItemCommand } from "@aws-sdk/client-dynamodb";

const db = new DynamoDBClient({ region: process.env.AWS_REGION });
const TABLE_NAME = process.env.EVENTS_TABLE || "EventsTable";

export const main = async (event: any) => {
  for (const record of event.Records) {
    try {
      const payload = JSON.parse(record.Sns.Message);
      await db.send(
        new PutItemCommand({
          TableName: TABLE_NAME,
          Item: {
            companyId: { S: payload.companyId },
            eventId: { S: payload.eventId },
            userId: { S: payload.userId },
            eventType: { S: payload.eventType },
            timestamp: { S: payload.timestamp },
            metadata: { S: JSON.stringify(payload.metadata) },
            description: { S: payload.description },
          },
        })
      );
    } catch (err) {
      console.error("DynamoDB Worker Error:", err);
    }
  }
};
