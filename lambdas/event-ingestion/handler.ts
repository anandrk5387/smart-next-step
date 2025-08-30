import { APIGatewayProxyHandler } from 'aws-lambda';
import AWS from 'aws-sdk';

const sns = new AWS.SNS({ endpoint: `http://localhost:${process.env.LOCALSTACK_EDGE_PORT}` });

export const main: APIGatewayProxyHandler = async (event) => {
  const body = event.body ? JSON.parse(event.body) : {};

  await sns.publish({
    TopicArn: process.env.EVENT_TOPIC_ARN,
    Message: JSON.stringify(body),
  }).promise();

  return {
    statusCode: 200,
    body: JSON.stringify({ eventId: body.eventId || 'evt_dummy' }),
  };
};
