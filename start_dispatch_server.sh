#!/bin/bash

# Function to start a Dockerized GitHub dispatch server
function start_dispatch_server {
    DISPATCH_NAME_PREFIX=$1
    ACCESS_TOKEN=$2
    RUNNER_GROUP="Default"
    LABELS="self-hosted,Linux,X64"
    ORG_NAME="alliance-genome"
    IMAGE_TAG="latest"
    REPO_URL="https://github.com/alliance-genome"
    RUNNER_UID=1001  # Non-root user ID inside the container

    echo "Using the following settings (excluding ACCESS_TOKEN):"
    echo "DISPATCH_NAME_PREFIX: $DISPATCH_NAME_PREFIX"
    echo "RUNNER_GROUP: $RUNNER_GROUP"
    echo "LABELS: $LABELS"
    echo "ORG_NAME: $ORG_NAME"
    echo "IMAGE_TAG: $IMAGE_TAG"
    echo "REPO_URL: $REPO_URL"

    DISPATCH_NAME="${DISPATCH_NAME_PREFIX}-dispatch"
    CONTAINER_NAME="${DISPATCH_NAME_PREFIX}-dispatch"

    echo "Generated DISPATCH_NAME: $DISPATCH_NAME"
    echo "Generated CONTAINER_NAME: $CONTAINER_NAME"

    LABELS="${LABELS},${DISPATCH_NAME}"

    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "Removing existing container with name $CONTAINER_NAME"
        docker rm -f $CONTAINER_NAME
    fi

    echo "Starting Docker container..."
    docker run -d --name $CONTAINER_NAME --restart unless-stopped \
        -e RUNNER_NAME="$DISPATCH_NAME" \
        -e ACCESS_TOKEN="$ACCESS_TOKEN" \
        -e RUNNER_GROUP="$RUNNER_GROUP" \
        -e RUNNER_SCOPE="org" \
        -e ORG_NAME="$ORG_NAME" \
        -e START_DOCKER_SERVICE="true" \
        -e REPO_URL="$REPO_URL" \
        -e LABELS="$LABELS" \
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
}

# Check if the script is being run with arguments and call the function
if [ $# -lt 2 ]; then
    echo "Usage: $0 DISPATCH_NAME_PREFIX ACCESS_TOKEN"
    exit 1
else
    start_dispatch_server "$1" "$2"
fi
