#!/usr/bin/env bash
set -euo pipefail

echo "🔹 [stop-localstack] Stopping LocalStack docker-compose..."
docker-compose down || true

echo "🔹 [stop-localstack] Pruning unused docker volumes (confirm)..."
docker volume prune -f || true

echo "✅ [stop-localstack] Done."
