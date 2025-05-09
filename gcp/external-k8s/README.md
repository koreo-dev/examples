# GCP Environment Workflow

This workflow provisions and configures a complete GCP-based Kubernetes environment using the `koreo.dev` workflow engine and custom `ResourceFunction` and `ValueFunction` modules.

It creates the necessary network infrastructure, a GKE cluster, service accounts, and sets up Workload Identity to allow Kubernetes ServiceAccounts to impersonate GCP Service Accounts securely.

## Overview

- **CRD Reference**: Targets the `GcpEnvironment` CRD defined under `acme.example.com/v1beta1`.
- **Inputs**: Expects a `parent` object.
- **Output**: A fully provisioned Kubernetes cluster with Workload Identity configured.

## Workflow Steps

| Step | Description |
|------|-------------|
| `metadata` | Generates standard metadata used across all resources. |
| `network` | Creates a VPC network for the environment. |
| `subnet` | Provisions a subnet within the created VPC with CIDR `10.10.0.0/16`. |
| `firewall` | Configures firewall rules for the subnet. |
| `k8sCluster` | Provisions a GKE cluster using the created VPC and subnet. |
| `k8sClusterSecret` | Extracts the Kubernetes API endpoint and CA cert to create a Kubernetes config secret. |
| `workloadIdentityServiceAccount` | Creates a GCP IAM Service Account used for Workload Identity. |
| `workloadIdentityPolicyMember` | Grants the IAM service account the necessary project-level permissions. |
| `ksaServiceAccount` | Creates a Kubernetes Service Account (KSA) annotated to impersonate the IAM Service Account. |
| `workloadIdentityPolicyMemberIdentKSA` | Grants the IAM service account permission to be impersonated by the KSA (`iam.workloadIdentityUser`). |
| `workloadIdentityPolicyMemberTokenKSA` | Grants the KSA permission to create identity tokens on behalf of the IAM service account (`iam.serviceAccountTokenCreator`). |

## Requirements

- GCP project with appropriate APIs enabled (IAM, GKE, Compute Engine).
- Koreo engine with support for `ResourceFunction` and `ValueFunction`.
- IAM permissions to create networks, clusters, service accounts, and IAM policies.

## Notes

- The workflow uses [Google Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) to enable secure communication between GCP and Kubernetes workloads.
- Each resource function should be implemented to create or reconcile its respective GCP or K8s object.
- The `metadata` step centralizes naming and labeling to ensure consistent tagging and traceability.


### Notes
- Ensure Koreo service account has permissions to edit IAM policy
  - I made it owner of the account, but this could be restricted I am sure.
- Ensure Identity and Access Management API is enabled
- Ensure Kubernetes API is enabled
- Ensure Cloud Resource Manager API is enabled
- To get the `koreo` service account you will need edit the above workflow to use the koreo service account or run the following commands.

``` sh
gcloud projects add-iam-policy-binding <TARGET_K8S_PROJECT_ID> \
  --member="serviceAccount:<TARGET_K8S_GSA_NAME>@<TARGET_K8S_PROJECT_ID>.iam.gserviceaccount.com" \
  --role="roles/container.developer"
```

``` sh
gcloud iam service-accounts add-iam-policy-binding \
  <TARGET_K8S_GSA_NAME>@<TARGET_K8S_PROJECT_ID>.iam.gserviceaccount.com \
  --role "roles/iam.workloadIdentityUser" \
  --member "serviceAccount:<HOST_K8S_PROJECT_ID>.svc.id.goog[<HOST_K8s_NAMESPACE>/koreo]"
```

``` sh
gcloud iam service-accounts add-iam-policy-binding \
  <TARGET_K8S_GSA_NAME>@<TARGET_K8S_PROJECT_ID>.iam.gserviceaccount.com \
  --role "roles/iam.serviceAccountTokenCreator" \
  --member "serviceAccount:<HOST_K8S_PROJECT_ID>.svc.id.goog[<HOST_K8s_NAMESPACE>/koreo]"
```

``` sh
# Edit serviceAccountName to koreo or whatever the workflow generates ("<GcpEnvironmentName>-workload-ksa")
# Edit the secret name references to the GcpEnvironmentName
kubectl apply -f ./fixtures/k8s-external-test.yaml

kubectl exec -it -n <TARGET_K8S_NAMESPACE> external-k8s -- /bin/sh

$ pip install pykube-ng google-auth
$ python
```

Run the following script to ensure your connection is working.

``` python 
import os
import base64
import tempfile
import yaml
from google.auth.transport.requests import Request
from google.auth import default
import pykube
from pykube import HTTPClient, KubeConfig

# Decode credentials passed in as env vars
cert = os.environ["GKE_CLUSTER_CA"].encode()
if cert.startswith(b"LS0"):
    cert = base64.b64decode(cert)  # only decode once if still encoded

token = None
creds, _ = default()
creds.refresh(Request())
token = creds.token

# Clean up endpoint
endpoint = os.environ["GKE_CLUSTER_ENDPOINT"]
if endpoint.startswith("https://"):
    endpoint = endpoint[len("https://"):]

# Build minimal kubeconfig
kubeconfig = {
    "apiVersion": "v1",
    "kind": "Config",
    "clusters": [{
        "name": "inline",
        "cluster": {
            "server": f"https://{endpoint}",
            "certificate-authority-data": base64.b64encode(cert).decode(),
        },
    }],
    "users": [{
        "name": "inline",
        "user": {
            "token": token,
        },
    }],
    "contexts": [{
        "name": "inline",
        "context": {
            "cluster": "inline",
            "user": "inline",
        },
    }],
    "current-context": "inline",
}

# Write to a named temporary file
kubeconfig_path = "/tmp/inline-kubeconfig.yaml"
with open(kubeconfig_path, "w") as f:
    yaml.safe_dump(kubeconfig, f)

print(f"Wrote kubeconfig to {kubeconfig_path}")

# Load and use it
api = HTTPClient(KubeConfig.from_file(kubeconfig_path))

for pod in pykube.Pod.objects(api).filter(namespace="kube-system"):
    print(pod.name)
```
