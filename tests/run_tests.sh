#!/bin/bash
set -e

echo "Starting database container..."
docker compose up -d db

echo "Building web service..."
docker compose build web

echo "Running tests..."
# Use -T flag to disable TTY allocation
docker compose run --rm -T web pytest -v --cov=app

# Store the exit code
exit_code=$?

echo "Cleaning up..."
docker compose down

# Exit with the test exit code
exit $exit_code
