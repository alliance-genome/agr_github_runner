#!/bin/bash

AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
AWS_DEFAULT_REGION="us-east-1"
REGISTRY="100225593120.dkr.ecr.us-east-1.amazonaws.com"

echo "Logging in to ECR..."
if echo "$REGISTRY" | egrep "ecr\..+\.amazonaws\.com"; then
  docker run --rm -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" amazon/aws-cli ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login -u AWS --password-stdin https://"$REGISTRY"
fi
