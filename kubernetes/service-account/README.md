# Service Account

This example shows a Workflow that builds a Kubernetes Service Account, RBAC
Role, and RoleBinding. This Workflow is intended to run as a sub-Workflow but
includes a `crdRef` that allows testing it with a `TriggerDummy` CRD. This
example also demonstrates bundling a complete Workflow with its associated
resources in a single .koreo file.
