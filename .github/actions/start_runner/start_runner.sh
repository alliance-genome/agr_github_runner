#!/bin/bash

ACCESS_TOKEN="${CREATE_RUNNER_TOKEN}"
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

suffix=1
while docker ps --format '{{.Names}}' | grep -q "^${RUNNER_NAME_PREFIX}-${suffix}$"; do
    ((suffix++))
done
RUNNER_NAME="${RUNNER_NAME_PREFIX}-${suffix}"
CONTAINER_NAME="flysql26-${suffix}"

echo "Generated RUNNER_NAME: $RUNNER_NAME"
echo "Generated CONTAINER_NAME: $CONTAINER_NAME"

LABELS="${LABELS},${UUID}"

if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "Removing existing container with name $CONTAINER_NAME"
    docker rm -f $CONTAINER_NAME
fi

echo "Starting Docker container..."
docker run --rm -d --privileged --name $CONTAINER_NAME \
    -e RUNNER_NAME="$RUNNER_NAME" \
    -e ACCESS_TOKEN="$ACCESS_TOKEN" \
    -e RUNNER_GROUP="$RUNNER_GROUP" \
    -e RUNNER_SCOPE="org" \
    -e DISABLE_AUTO_UPDATE="true" \
    -e ORG_NAME="$ORG_NAME" \
    -e LABELS="$LABELS" \
    -e EPHEMERAL=1 \
    -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
    -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
    -e START_DOCKER_SERVICE=true \
    myoung34/github-runner:$IMAGE_TAG

if [ $? -eq 0 ]; then
    echo "Docker container $CONTAINER_NAME started successfully."
else
    echo "Failed to start Docker container $CONTAINER_NAME."
    exit 1
fi

sleep 5

if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "Container $CONTAINER_NAME has stopped unexpectedly. Fetching logs..."
    docker logs $CONTAINER_NAME
else
    echo "Container $CONTAINER_NAME is running."
fi
