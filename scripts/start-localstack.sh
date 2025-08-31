#!/bin/bash
set -e

echo "🔹 Creating Docker network if it doesn't exist..."
docker network inspect $LAMBDA_DOCKER_NETWORK >/dev/null 2>&1 || \
docker network create $LAMBDA_DOCKER_NETWORK

echo "🔹 Starting LocalStack + Qdrant..."
docker-compose up -d

echo "🔹 Waiting for LocalStack STS to be ready..."
until docker exec localstack-main awslocal sts get-caller-identity >/dev/null 2>&1; do
  echo "   ⏳ LocalStack not ready yet, waiting 5s..."
  sleep 5
done
