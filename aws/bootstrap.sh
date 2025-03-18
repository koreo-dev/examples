export S3_RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/s3-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')
export LAMBDA_RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/lambda-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')
export IAM_RELEASE_VERSION=$(curl -sL https://api.github.com/repos/aws-controllers-k8s/iam-controller/releases/latest | jq -r '.tag_name | ltrimstr("v")')
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ACK_SYSTEM_NAMESPACE=ack-system
export AWS_REGION=us-west-2

aws ecr-public get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin public.ecr.aws
helm upgrade --install --create-namespace -n $ACK_SYSTEM_NAMESPACE ack-s3-controller \
  oci://public.ecr.aws/aws-controllers-k8s/s3-chart --version=$S3_RELEASE_VERSION --set=aws.region=$AWS_REGION --set=aws.account_id=$AWS_ACCOUNT_ID \
  --set=deployment.extraEnvVars[0].name=AWS_ACCESS_KEY_ID --set=deployment.extraEnvVars[0].value=$AWS_ACCESS_KEY_ID \
  --set=deployment.extraEnvVars[1].name=AWS_SECRET_ACCESS_KEY --set=deployment.extraEnvVars[1].value=$AWS_SECRET_ACCESS_KEY
helm upgrade --install --create-namespace -n $ACK_SYSTEM_NAMESPACE ack-lambda-controller \
  oci://public.ecr.aws/aws-controllers-k8s/lambda-chart --version=$LAMBDA_RELEASE_VERSION --set=aws.region=$AWS_REGION --set=aws.account_id=$AWS_ACCOUNT_ID \
  --set=deployment.extraEnvVars[0].name=AWS_ACCESS_KEY_ID --set=deployment.extraEnvVars[0].value=$AWS_ACCESS_KEY_ID \
  --set=deployment.extraEnvVars[1].name=AWS_SECRET_ACCESS_KEY --set=deployment.extraEnvVars[1].value=$AWS_SECRET_ACCESS_KEY
helm upgrade --install --create-namespace -n $ACK_SYSTEM_NAMESPACE ack-iam-controller \
  oci://public.ecr.aws/aws-controllers-k8s/iam-chart --version=$IAM_RELEASE_VERSION --set=aws.region=$AWS_REGION --set=aws.account_id=$AWS_ACCOUNT_ID  \
  --set=deployment.extraEnvVars[0].name=AWS_ACCESS_KEY_ID --set=deployment.extraEnvVars[0].value=$AWS_ACCESS_KEY_ID \
  --set=deployment.extraEnvVars[1].name=AWS_SECRET_ACCESS_KEY --set=deployment.extraEnvVars[1].value=$AWS_SECRET_ACCESS_KEY

kubectl apply -f lambda-workload-crd.yaml
