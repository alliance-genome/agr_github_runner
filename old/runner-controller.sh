#!/bin/bash

# Function to start a Dockerized GitHub runner using the existing script
function start_runner {
    ACCESS_TOKEN=$1
    AWS_ACCESS_KEY_ID=$2
    AWS_SECRET_ACCESS_KEY=$3
    UUID=$4
    
    /var/go/agr_github_runner/github-runner.sh $ACCESS_TOKEN $AWS_ACCESS_KEY_ID $AWS_SECRET_ACCESS_KEY $UUID
}

# Function to stop a Dockerized GitHub runner
function stop_runner {
    UUID=$1
    echo "Stopping Docker container with label $UUID..."
    CONTAINER_ID=$(docker ps -q -f label=$UUID)
    if [ -n "$CONTAINER_ID" ]; then
        docker stop $CONTAINER_ID
    else
        echo "No running container found with label $UUID. It may have already stopped."
    fi
}

# Parse command line arguments
COMMAND=$1
shift

if [ "$COMMAND" == "start" ]; then
    start_runner "$@"
elif [ "$COMMAND" == "stop" ]; then
    stop_runner "$@"
else
    echo "Usage: $0 {start|stop} ACCESS_TOKEN AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY UUID"
    exit 1
fi
