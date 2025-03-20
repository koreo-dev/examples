# Lambda Workload

In this example, we will create a workflow that will take as an input, a simple KRM object that will
ultimately create a S3 bucket. Next, a policy will be created that has the ability to read or write 
to that specific bucket. Then a lambda execution role that can use said policy will be created and
attached to a lambda function. The image has the ability to write the event payload to a json file 
in the new bucket. So at the end we can test our work by invoking the lambda and checking for new
objects in our bucket. 

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
./scripts/install-koreo.sh
```

7. Trigger the workflow

``` sh
kubectl apply -f hello-lambda-workload.yaml
```

8. Check on status of workload

```
kubectl get lambdaworkloads -n koreo-examples hello-lambda-workload -o yaml 
```
