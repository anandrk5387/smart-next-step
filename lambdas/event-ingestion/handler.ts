import { APIGatewayProxyHandler } from 'aws-lambda';
import AWS from 'aws-sdk';

const sns = new AWS.SNS({ endpoint: `http://localhost:${process.env.LOCALSTACK_EDGE_PORT}` });

export const main: APIGatewayProxyHandler = async (event) => {
  try {
    const body = event.body ? JSON.parse(event.body) : {};
    const message = {
      userId: body.userId || 'unknown',
      event: body.event || 'dummy_event',
    };

    await sns.publish({
      TopicArn: process.env.EVENT_TOPIC_ARN,
      Message: JSON.stringify(message),
    }).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({ status: 'ok', eventId: message.event }),
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: 'Failed to publish event', details: err }),
    };
  }
};
