import AWS from "aws-sdk";

const sns = new AWS.SNS({ endpoint: `http://localhost:${process.env.LOCALSTACK_EDGE_PORT}` });

export const main = async (event: any) => {
  console.log("Lambda invoked:", event);

  await sns.publish({
    TopicArn: process.env.RECOMMEND_TOPIC_ARN!,
    Message: JSON.stringify(event),
  }).promise();

  return {
    statusCode: 200,
    body: JSON.stringify({ message: "Recommendation sent" }),
  };
};
