#!/bin/bash

# Function to setup an ephemeral GitHub runner for an organization
function github-runner {
    # Check for ACCESS_TOKEN
    if [ -z "$1" ]; then
        echo "Error: ACCESS_TOKEN is not set. Please provide the access token as the first argument."
        return 1
    fi
    
    ACCESS_TOKEN=$1
    AWS_ACCESS_KEY_ID=$2
    AWS_SECRET_ACCESS_KEY=$3
    UUID=$4
    RUNNER_NAME_PREFIX=${5:-$(uname -n)}
    RUNNER_GROUP=${6:-Default}
    LABELS=${7:-self-hosted,Linux,X64}
    IMAGE_TAG=${8:-latest}
    ORG_NAME="alliance-genome"

    echo "Using the following settings:"
    echo "ACCESS_TOKEN: <hidden>"
    echo "RUNNER_NAME_PREFIX: $RUNNER_NAME_PREFIX"
    echo "RUNNER_GROUP: $RUNNER_GROUP"
    echo "LABELS: $LABELS"
    echo "IMAGE_TAG: $IMAGE_TAG"
    echo "ORG_NAME: $ORG_NAME"
    echo "UUID: $UUID"

    # Check for existing runners and assign the lowest available name
    suffix=1
    while docker ps --format '{{.Names}}' | grep -q "^${RUNNER_NAME_PREFIX}-${suffix}$"; do
        ((suffix++))
    done
    RUNNER_NAME="${RUNNER_NAME_PREFIX}-${suffix}"
    CONTAINER_NAME="github-org-runner-${suffix}"

    echo "Generated RUNNER_NAME: $RUNNER_NAME"
    echo "Generated CONTAINER_NAME: $CONTAINER_NAME"

    # Append the UUID to LABELS
    LABELS="${LABELS},${UUID}"

    # Remove any existing container with the same name
    if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "Removing existing container with name $CONTAINER_NAME"
        docker rm -f $CONTAINER_NAME
    fi

    # Run the Docker container in privileged mode
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
        return 1
    fi

    # Wait for a few seconds to allow any immediate failures to occur
    sleep 5

    # Check if the container is still running
    if ! docker ps --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
        echo "Container $CONTAINER_NAME has stopped unexpectedly. Fetching logs..."
        docker logs $CONTAINER_NAME
    else
        echo "Container $CONTAINER_NAME is running."
    fi
}

# Check if the script is being run with arguments and call the function
if [ $# -gt 0 ]; then
    github-runner "$@"
else
    echo "Usage: $0 ACCESS_TOKEN AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY UUID [RUNNER_NAME_PREFIX] [RUNNER_GROUP] [LABELS] [IMAGE_TAG]"
    echo "Example: $0 <your-access-token> <aws-access-key-id> <aws-secret-access-key> <uuid>"
fi

# Script usage explanation:
# 1. ACCESS_TOKEN: The access token for your GitHub organization. This is required and should be provided as the first argument to the function.
# 2. AWS_ACCESS_KEY_ID: The AWS access key ID. This is required and should be provided as the second argument.
# 3. AWS_SECRET_ACCESS_KEY: The AWS secret access key. This is required and should be provided as the third argument.
# 4. UUID: The unique identifier for the runner. This is required and should be provided as the fourth argument.
# 5. RUNNER_NAME_PREFIX: (Optional) Prefix for the runner name. Defaults to the output of `uname -n`.
# 6. RUNNER_GROUP: (Optional) The runner group name. Defaults to "Default".
# 7. LABELS: (Optional) Labels to assign to the runner. Defaults to "self-hosted,Linux,X64".
# 8. IMAGE_TAG: (Optional) Docker image tag for the GitHub runner. Defaults to "latest".

# To use the script, save it to a file, make it executable with chmod +x scriptname.sh,
# and then run it from your terminal with the necessary arguments.
