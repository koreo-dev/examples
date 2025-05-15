# GCP Environment Workflow

This workflow provisions and configures a GCP-based environment using the `koreo.dev` workflow engine and custom `ResourceFunction` and `ValueFunction` modules.

Included in the environment are a VPC, Subnet, and Firewall.

## Overview

- **CRD Reference**: Targets the `GcpEnvironment` CRD defined under `example.koreo.dev/v1beta1`.
- **Inputs**: Expects a `parent` object.
- **Output**: An example vpc and subnet with a firewall

## Workflow Steps

| Step | Description |
|------|-------------|
| `metadata` | Generates standard metadata used across all resources. |
| `network` | Creates a VPC network for the environment. |
| `subnet` | Provisions a subnet within the created VPC with CIDR `10.10.0.0/16`. |
| `firewall` | Configures firewall rules for the subnet. |

## Requirements

- GCP project with appropriate APIs enabled (IAM, Compute Engine).
- Koreo engine with support for `ResourceFunction` and `ValueFunction`.
- IAM permissions to create the various vpc resources
