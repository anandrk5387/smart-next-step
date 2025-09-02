import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";
import { APIGatewayProxyHandler } from "aws-lambda";

const sns = new SNSClient({ region: process.env.AWS_REGION });

export const main: APIGatewayProxyHandler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");

    if (!body.companyId || !body.userId || !body.eventType) {
      return { statusCode: 400, body: "Missing required fields" };
    }

    const message = {
      ...body,
      timestamp: new Date().toISOString(),
      eventId: body.eventId || `evt_${Date.now()}`,
    };

    // Publish to SNS
    const topicArn = process.env.EVENT_TOPIC_ARN!;
    await sns.send(new PublishCommand({ TopicArn: topicArn, Message: JSON.stringify(message) }));

    return {
      statusCode: 200,
      body: JSON.stringify({ eventId: message.eventId }),
    };
  } catch (err: any) {
    console.error(err);
    return { statusCode: 500, body: "Internal server error" };
  }
};
