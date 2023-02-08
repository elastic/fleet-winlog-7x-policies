// Create Agent policy. Ignore failures if it already exists. This should be replaced by
// a proper terraform provider for Fleet (this is a hack).
resource "null_resource" "create-agent-policy" {
  provisioner "local-exec" {
    command = <<EOT
curl \
  -XPOST \
  --fail-with-body \
  --header "Content-Type: application/json" \
  --header "kbn-xsrf: true" \
  --header "Authorization: $BASIC_AUTH" \
  "$KIBANA_URL/api/fleet/agent_policies" \
  -d '${jsonencode({
    "name" : "Windows",
    "description" : "Collect Windows event logs.",
    "namespace" : "default",
    "monitoring_enabled" : ["logs", "metrics"]
})}'
EOT

environment = {
  BASIC_AUTH = local.basic_auth
  KIBANA_URL = local.kibana_url
}
}

triggers = {
  always_run = timestamp()
}
}

// Get agent policy ID for the policy named "Windows".
data "http" "get-agent-policy" {
  url    = "${local.kibana_url}/api/fleet/agent_policies?kuery=name:%20Windows"
  method = "GET"

  request_headers = {
    Authorization = local.basic_auth
    Accept        = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid"
    }
  }

  depends_on = [null_resource.create-agent-policy]
}

// Load a policy to read the winlog package version.
data "local_file" "policy" {
  filename = "${path.module}/../../policy-winlog-security.json"
}

locals {
  agent_policy_id = jsondecode(data.http.get-agent-policy.response_body).items[0].id

  winlog_version = jsondecode(data.local_file.policy.content).package.version
}

// Prevent concurrency issues by installing the package before adding
// package policies to Agent policy. It prevents errors like:
//
// {"statusCode":409,"error":"Conflict","message":"Error installing winlog
// 1.10.0: Concurrent installation or upgrade of winlog-1.10.0 detected,
// aborting."}
//
// The force parameter allows installation of the non-latest package version.
resource "null_resource" "install-winlog" {
  provisioner "local-exec" {
    command = <<EOT
curl \
  -XPOST \
  --fail-with-body \
  --header "Content-Type: application/json" \
  --header "kbn-xsrf: true" \
  --header "Authorization: $BASIC_AUTH" \
  "$KIBANA_URL/api/fleet/epm/packages/winlog/${local.winlog_version}" \
  -d '{"force": true}'
EOT

    environment = {
      BASIC_AUTH = local.basic_auth
      KIBANA_URL = local.kibana_url
    }
  }

  triggers = {
    always_run = timestamp()
  }
}

// Install package policies using the policy-*.json files in the root of this repo.
// Ignore failures if it already exists. This should be replaced by a proper terraform
// provider for Fleet (this is a hack).
resource "null_resource" "add-winlog-integrations" {
  for_each = fileset(path.module, "../../policy-*.json")

  provisioner "local-exec" {
    command = <<EOT
bash -c 'curl \
  -XPOST \
  --fail-with-body \
  --header "Content-Type: application/json" \
  --header "kbn-xsrf: true" \
  --header "Authorization: $BASIC_AUTH" \
  "$KIBANA_URL/api/fleet/package_policies" \
  -d @<(cat ${each.key} | envsubst)'
EOT

    environment = {
      BASIC_AUTH      = local.basic_auth
      KIBANA_URL      = local.kibana_url
      AGENT_POLICY_ID = local.agent_policy_id
    }
  }

  triggers = {
    always_run = timestamp()
  }

  depends_on = [null_resource.install-winlog]
}

// Get enrollment tokens. Then we will filter the tokens to find the key
// associated with the agent policy that was created earlier.
data "http" "enrollment-key" {
  url = "${local.kibana_url}/api/fleet/enrollment_api_keys"

  request_headers = {
    Authorization = local.basic_auth
    Accept        = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid"
    }
  }

  depends_on = [data.http.get-agent-policy]
}

// Filter the enrollment keys to match the key with policy_id equal to our agent policy ID.
locals {
  enrollment_api_keys = jsondecode(data.http.enrollment-key.response_body).items
  enrollment_api_key  = [for item in local.enrollment_api_keys : item if item.policy_id == local.agent_policy_id][0]
}