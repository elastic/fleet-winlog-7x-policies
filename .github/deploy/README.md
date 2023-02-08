# Deployment Test

This Terraform module deploys the package policies to an Elastic Cloud instance.

1. Provision Elasticsearch, Kibana, and Fleet Server on Elastic Cloud.
2. Create an Agent policy.
3. Install the winlog integration.
4. Add each winlog package policy to the Agent policy.
5. Get the fleet enrollment token associated to the Agent policy.
6. Create an API key to read data from `logs-winlog.*`.

NOTE: This module uses a local-exec hack to workaround the lack of a Fleet
terraform provider. See https://github.com/elastic/terraform-provider-elasticstack/issues/89.

## Maintenance

The only value that needs updated is the `stack_version` variable. This
should be updated to test with the latest stack release. And because this
uses the Elastic Cloud Staging it is possible to test with pre-release
stack versions.