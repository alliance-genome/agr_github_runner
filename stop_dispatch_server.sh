#!/bin/bash

# Function to stop a Dockerized GitHub dispatch server and runner manager
function stop_dispatch_server {
    DISPATCH_NAME_PREFIX=$1
    CONTAINER_NAME="${DISPATCH_NAME_PREFIX}-dispatch"
    RUNNER_MANAGER_CONTAINER="runner-manager"
    NETWORK_NAME="my-network"

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

    echo "Stopping and removing runner manager container..."

    if docker ps --format '{{.Names}}' | grep -q "^$RUNNER_MANAGER_CONTAINER$"; then
        docker stop $RUNNER_MANAGER_CONTAINER
        if [ $? -eq 0 ]; then
            echo "Runner manager container $RUNNER_MANAGER_CONTAINER stopped successfully."
        else
            echo "Failed to stop runner manager container $RUNNER_MANAGER_CONTAINER."
            exit 1
        fi
    else
        echo "No running container with name $RUNNER_MANAGER_CONTAINER found."
    fi

    if docker ps -a --format '{{.Names}}' | grep -q "^$RUNNER_MANAGER_CONTAINER$"; then
        docker rm $RUNNER_MANAGER_CONTAINER
        if [ $? -eq 0 ]; then
            echo "Runner manager container $RUNNER_MANAGER_CONTAINER removed successfully."
        else
            echo "Failed to remove runner manager container $RUNNER_MANAGER_CONTAINER."
            exit 1
        fi
    else
        echo "No container with name $RUNNER_MANAGER_CONTAINER found to remove."
    fi

    echo "Removing Docker network $NETWORK_NAME..."

    if docker network ls --format '{{.Name}}' | grep -q "^$NETWORK_NAME$"; then
        docker network rm $NETWORK_NAME
        if [ $? -eq 0 ]; then
            echo "Docker network $NETWORK_NAME removed successfully."
        else
            echo "Failed to remove Docker network $NETWORK_NAME."
            exit 1
        fi
    else
        echo "No Docker network with name $NETWORK_NAME found to remove."
    fi
}

# Check if the script is being run with arguments and call the function
if [ $# -lt 1 ]; then
    echo "Usage: $0 DISPATCH_NAME_PREFIX"
    exit 1
else
    stop_dispatch_server "$1"
fi
