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
    NETWORK_NAME="my-network"

    echo "Using the following settings (excluding ACCESS_TOKEN):"
    echo "DISPATCH_NAME_PREFIX: $DISPATCH_NAME_PREFIX"
    echo "RUNNER_GROUP: $RUNNER_GROUP"
    echo "LABELS: $LABELS"
    echo "ORG_NAME: $ORG_NAME"
    echo "IMAGE_TAG: $IMAGE_TAG"
    echo "REPO_URL: $REPO_URL"
    echo "NETWORK_NAME: $NETWORK_NAME"

    DISPATCH_NAME="${DISPATCH_NAME_PREFIX}-dispatch"
    CONTAINER_NAME="${DISPATCH_NAME_PREFIX}-dispatch"
    RUNNER_MANAGER_CONTAINER="runner-manager"

    echo "Generated DISPATCH_NAME: $DISPATCH_NAME"
    echo "Generated CONTAINER_NAME: $CONTAINER_NAME"

    LABELS="${LABELS},${DISPATCH_NAME}"

    # Check if the Docker network exists, and create it if it doesn't
    if ! docker network ls --format '{{.Name}}' | grep -q "^$NETWORK_NAME$"; then
        echo "Creating Docker network $NETWORK_NAME..."
        docker network create $NETWORK_NAME
        if [ $? -eq 0 ]; then
            echo "Docker network $NETWORK_NAME created successfully."
        else
            echo "Failed to create Docker network $NETWORK_NAME."
            exit 1
        fi
    else
        echo "Docker network $NETWORK_NAME already exists."
    fi

    # Start the runner manager container if it's not already running
    if ! docker ps --format '{{.Names}}' | grep -q "^$RUNNER_MANAGER_CONTAINER$"; then
        echo "Starting runner manager container..."
        docker build -t my-runner-manager-image ./runner_manager
        docker run -d --name $RUNNER_MANAGER_CONTAINER --network $NETWORK_NAME -p 5000:5000 my-runner-manager-image
        if [ $? -eq 0 ]; then
            echo "Runner manager container started successfully."
        else
            echo "Failed to start runner manager container."
            exit 1
        fi
    else
        echo "Runner manager container is already running."
    fi

    # Remove any existing container with the same name
    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "Removing existing container with name $CONTAINER_NAME"
        docker rm -f $CONTAINER_NAME
    fi

    echo "Starting Docker container for dispatch..."
    docker run -d --name $CONTAINER_NAME --network $NETWORK_NAME --restart unless-stopped \
        -e RUNNER_NAME="$DISPATCH_NAME" \
        -e ACCESS_TOKEN="$ACCESS_TOKEN" \
        -e RUNNER_GROUP="$RUNNER_GROUP" \
        -e RUNNER_SCOPE="org" \
        -e ORG_NAME="$ORG_NAME" \
        -e REPO_URL="$REPO_URL" \
        -e LABELS="$LABELS" \
        -e EPHEMERAL="true" \
        -e RUN_AS_ROOT="false" \
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

    # Check communication with the runner manager container
    echo "Checking communication with runner manager container..."
    response=$(docker exec $CONTAINER_NAME curl -s -o /dev/null -w "%{http_code}" -X POST http://runner-manager:5000/start-runner -H "Content-Type: application/json" -d '{}')

    if [ "$response" -eq 200 ] || [ "$response" -eq 400 ]; then
        echo "Successfully communicated with the runner manager container."
    else
        echo "Failed to communicate with the runner manager container. HTTP response code: $response"
        docker exec $CONTAINER_NAME curl -v -X POST http://runner-manager:5000/start-runner -H "Content-Type: application/json" -d '{}'
        exit 1
    fi
}

# Check if the script is being run with arguments and call the function
if [ $# -lt 2 ]; then
    echo "Usage: $0 DISPATCH_NAME_PREFIX ACCESS_TOKEN"
    exit 1
else
    start_dispatch_server "$1" "$2"
fi
