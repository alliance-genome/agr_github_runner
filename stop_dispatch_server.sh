#!/bin/bash

# Function to stop a Dockerized GitHub dispatch server
function stop_dispatch_server {
    DISPATCH_NAME_PREFIX=$1
    CONTAINER_NAME="${DISPATCH_NAME_PREFIX}-dispatch"

    echo "Stopping and removing Docker container with name $CONTAINER_NAME..."

    if docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        docker stop $CONTAINER_NAME
        if [ $? -eq 0 ]; then
            echo "Docker container $CONTAINER_NAME stopped successfully."
        else
            echo "Failed to stop Docker container $CONTAINER_NAME."
            exit 1
        fi
    else
        echo "No running container with name $CONTAINER_NAME found."
    fi

    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        docker rm $CONTAINER_NAME
        if [ $? -eq 0 ]; then
            echo "Docker container $CONTAINER_NAME removed successfully."
        else
            echo "Failed to remove Docker container $CONTAINER_NAME."
            exit 1
        fi
    else
        echo "No container with name $CONTAINER_NAME found to remove."
    fi
}

# Check if the script is being run with arguments and call the function
if [ $# -lt 1 ]; then
    echo "Usage: $0 DISPATCH_NAME_PREFIX"
    exit 1
else
    stop_dispatch_server "$1"
fi