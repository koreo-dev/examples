#!/usr/bin/env bash

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr create-repository --repository-name my-lambda-image --region us-east-1 || true && \ 
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com && \
docker build buildx --platform linux/amd64 -t $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-lambda-image:latest ../docker && \
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/my-lambda-image:latest
