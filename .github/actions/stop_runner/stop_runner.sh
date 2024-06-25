#!/bin/bash

ACCESS_TOKEN="${ACCESS_TOKEN}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
UUID="${UUID}"

echo "Stopping Docker container with label $UUID..."
CONTAINER_ID=$(docker ps -q -f label=$UUID)
if [ -n "$CONTAINER_ID" ]; then
    docker stop $CONTAINER_ID
else
    echo "No running container found with label $UUID. It may have already stopped."
fi