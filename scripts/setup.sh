#!/bin/bash
set -e

echo "🔹 Checking Node.js version..."
node -v
npm -v

echo "🔹 Installing project dependencies..."
npm install --legacy-peer-deps

echo "🔹 Installing Serverless CLI globally..."
npm install -g serverless

echo "🔹 Verifying Serverless CLI..."
sls --version

# Optional: Serverless login if needed
echo "🔹 Logging in to Serverless..."
sls login

echo "🔹 Loading environment variables..."
export $(grep -v '^#' .env.local | xargs)

echo "🔹 Installing awslocal (awscli-local) if not installed..."
if ! command -v awslocal &> /dev/null; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Installing awslocal via pipx (macOS)..."
    brew install pipx || true
    pipx ensurepath
    pipx install awscli-local
  else
    echo "Installing awslocal via pip (Linux)..."
    python3 -m pip install --user awscli-local
  fi
fi

# Add Python user base bin directory to PATH
export PATH="$HOME/.local/bin:$PATH"
# Linux might be: export PATH="$HOME/.local/bin:$PATH"
awslocal --version

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

echo "🔹 Deploying Serverless infrastructure..."
npx serverless deploy --stage dev

echo "🔹 Loading sample events..."
if [[ -f scripts/load-data.sh ]]; then
  bash scripts/load-data.sh
else
  echo "⚠️ scripts/load-data.sh not found, skipping sample events load."
fi

echo "✅ System is ready!"
echo "Test endpoints:"
echo "POST /events -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/.../events"
echo "GET /recommendations?user_id=... -> http://localhost:${LOCALSTACK_EDGE_PORT}/restapis/.../recommendations"
