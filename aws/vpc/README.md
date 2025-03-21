# VPC

This example demonstrates building a VPC with an internet gateway, route table,
and public subnets. This is exposed through an AwsEnvironment abstraction. This
example also shows how consistent metadata labels and AWS tags can be applied
across resources. This uses [ACK](https://aws-controllers-k8s.github.io/community/docs/community/overview/)
for provisioning AWS resources.
