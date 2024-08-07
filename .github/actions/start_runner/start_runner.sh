#!/bin/bash

ACCESS_TOKEN="${ACCESS_TOKEN}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
UUID="${UUID}"
RUNNER_NAME_PREFIX="flysql26"
RUNNER_GROUP="Default"
LABELS="self-hosted,Linux,X64"
IMAGE_TAG="latest"
ORG_NAME="alliance-genome"
RUNNER_UID=1001  # Non-root user ID inside the container

# Print diagnostic information
echo "Diagnostic Information:"
echo "Hostname: $(hostname)"
echo "Current User: $(whoami)"
echo "Current Directory: $(pwd)"
echo "Operating System: $(uname -a)"
echo "Docker Version: $(docker --version)"
echo "Docker Info: $(docker info --format '{{json .}}')"
echo

echo "Using the following settings:"
echo "ACCESS_TOKEN: <hidden>"
echo "RUNNER_NAME_PREFIX: $RUNNER_NAME_PREFIX"
echo "RUNNER_GROUP: $RUNNER_GROUP"
echo "LABELS: $LABELS"
echo "IMAGE_TAG: $IMAGE_TAG"
echo "ORG_NAME: $ORG_NAME"
echo "UUID: $UUID"

RUNNER_NAME="${RUNNER_NAME_PREFIX}-${UUID}"
CONTAINER_NAME="flysql26-${UUID}"

echo "Generated RUNNER_NAME: $RUNNER_NAME"
echo "Generated CONTAINER_NAME: $CONTAINER_NAME"

LABELS="${LABELS},${UUID}"

# Ensure a writable temporary directory for response
TEMP_DIR=$(mktemp -d)
RESPONSE_FILE="$TEMP_DIR/response.txt"

# Send request to runner manager and capture response and HTTP status code
echo "Sending request to runner manager..."
response=$(curl -s -o "$RESPONSE_FILE" -w "%{http_code}" -X POST http://localhost:5000/start-runner -H "Content-Type: application/json" -d '{
    "container_name": "'"$CONTAINER_NAME"'",
    "image_tag": "'"$IMAGE_TAG"'",
    "labels": "'"$LABELS"'",
    "access_token": "'"$ACCESS_TOKEN"'",
    "runner_name": "'"$RUNNER_NAME"'",
    "runner_group": "'"$RUNNER_GROUP"'",
    "runner_scope": "org",
    "org_name": "'"$ORG_NAME"'",
    "repo_url": "https://github.com/alliance-genome",
    "aws_access_key_id": "'"$AWS_ACCESS_KEY_ID"'",
    "aws_secret_access_key": "'"$AWS_SECRET_ACCESS_KEY"'"
}')

# Read the response from the file
response_body=$(<"$RESPONSE_FILE")

# Check if the runner was started successfully
if [[ $response == 200 && $response_body == *"Runner started successfully"* ]]; then
    echo "Runner container $CONTAINER_NAME started successfully."
else
    echo "Failed to start runner container $CONTAINER_NAME."
    echo "HTTP Response Code: $response"
    echo "Response Body: $response_body"
    echo "Script executed in directory: $(pwd)"
    echo "Response file location: $RESPONSE_FILE"
    exit 1
fi
