# Lambda Workload

In this example, we will create a Workflow that provisions four key AWS
resources in sequence. First, we define a simple KRM object to create an S3
bucket. Next, we generate a policy that grants read and write access to that
specific bucket. Third, we create a Lambda execution role that can assume this
policy. Finally, we attach the role to a Lambda function, which writes event
payloads as JSON files to the bucket. To validate our setup, we invoke the
Lambda function and check for new objects in the bucket. This example uses
[ACK](https://aws-controllers-k8s.github.io/community/docs/community/overview/)
for provisioning AWS resources.

# Prerequisites

1. `kubctl`
2. `helm`
3. `minikube`
4. `awscli`

# Setup Step
1. Publish a lambda docker image 

``` sh
./publish-image.sh
```

2. Verify Kube Context - Use local cluster to ensure private aws credentials are not shared.
```
kubectl config current-context
```

3. Install ack controllers into local cluster

``` sh
./scripts/bootstrap-ack.sh
```

4. Install Koreo Helm Chart 

The set-strings will grant super user and super reader access on the controller and ui respectfully.

``` sh
helm repo add koreo https://koreo.dev/helm
helm repo update
helm upgrade --install koreo-controller koreo/koreo \
  -n koreo-examples --create-namespace --values ./scripts/values.yaml

# To access the UI at localhost:8080, run the following in another window.
kubectl port-forward svc/koreo-controller-ui 8080:8080 -n koreo-examples
```

5. Install our Custom Lambda Workload CRD 

``` sh
kubectl apply -f ./src/crds/lambda-workload.yaml
```

6. Install our Koreo Functions and Workflow

``` sh
koreo apply ./src
```

7. Trigger the workflow

``` sh
kubectl apply -f hello-lambda-workload.yaml
```

8. Check on status of workload

```
kubectl get lambdaworkloads -n koreo-examples hello-lambda-workload -o yaml 
```
