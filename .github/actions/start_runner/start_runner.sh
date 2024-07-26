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

echo "Sending request to runner manager..."
response=$(curl -s -X POST http://<LOCAL_RUNNER_MANAGER_IP>:5000/start-runner -H "Content-Type: application/json" -d '{
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

if [[ $response == *"Runner started successfully"* ]]; then
    echo "Runner container $CONTAINER_NAME started successfully."
else
    echo "Failed to start runner container $CONTAINER_NAME."
    echo "Response: $response"
    exit 1
fi
