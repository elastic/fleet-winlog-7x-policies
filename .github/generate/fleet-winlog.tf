terraform {
  required_providers {
    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }
  }
}

provider "http" {}

variable "agent_policy_id" {
  type        = string
  description = "ID of the Agent policy to which the winlog packages will be added."
  default     = "87323640-a676-11ed-b7ad-57c2b61f1488"
}

variable "kibana_url" {
  type        = string
  description = "URL to kibana (e.g. https://localhost:5601)"
  default     = "https://localhost:5601"
}

variable "api_key" {
  type        = string
  description = "Elasticsearch API use to authenticate to Kibana (in base64 encoded format)."
  default     = "exampleZWUJHTHZPZHRHMnlfci06Y3ByU0Jva1hUYWEwQmR0NzVZRlpSQQ=="
}

variable "winlogbeat_version" {
  type        = string
  description = "Winlogbeat version to obtain the module script processor sources."
  default     = "v7.17.14"
}

variable "fleet_winlog_version" {
  type        = string
  description = "Version of the Fleet winlog integration. See https://docs.elastic.co/en/integrations/winlog#changelog"
  default     = "1.20.0"
}

variable "fleet_namespace" {
  type        = string
  description = "Data stream namespace to apply to all integrations."
  default     = "default"
}

locals {
  channels = [
    // https://www.elastic.co/guide/en/beats/winlogbeat/7.17/winlogbeat-module-security.html#_configuration_2
    {
      id        = "security"
      channel   = "Security"
      script    = data.http.winlogbeat-security-js.response_body
      event_ids = []
    },
    // https://www.elastic.co/guide/en/beats/winlogbeat/7.17/winlogbeat-module-powershell.html#_configuration
    {
      id        = "windows-powershell"
      channel   = "Windows PowerShell"
      script    = data.http.winlogbeat-powershell-js.response_body
      event_ids = [400, 403, 600, 800]
    },
    {
      id        = "powershell-operational"
      channel   = "Microsoft-Windows-PowerShell/Operational"
      script    = data.http.winlogbeat-powershell-js.response_body
      event_ids = [4103, 4104, 4105, 4106]
    },
    // https://www.elastic.co/guide/en/beats/winlogbeat/7.17/winlogbeat-module-sysmon.html
    {
      id        = "sysmon"
      channel   = "Sysmon"
      script    = data.http.winlogbeat-sysmon-js.response_body
      event_ids = []
    },
  ]

  // API docs:
  // https://www.elastic.co/guide/en/fleet/8.5/fleet-api-docs.html#create-integration-policy-api
  policies = [for policy in local.channels : {
    policy_id = "$AGENT_POLICY_ID"
    package = {
      name : "winlog",
      version : var.fleet_winlog_version,
    }
    name        = "winlog-${policy.id}"
    description = "Collect event logs from ${policy.channel}."
    namespace   = var.fleet_namespace,
    inputs = {
      winlogs-winlog = {
        enabled = true
        streams = {
          "winlog.winlog" = {
            enabled = true
            vars = {
              channel                 = policy.channel
              "data_stream.dataset"   = "winlog.${policy.id}"
              preserve_original_event = false
              providers               = []
              ignore_older            = "72h"
              language                = 0
              event_id                = join(",", policy.event_ids)
              tags                    = []
              custom = yamlencode({
                processors = [
                  {
                    script = {
                      lang   = "javascript"
                      id     = lower(policy.channel)
                      source = policy.script
                    }
                  },
                  {
                    drop_fields = {
                      ignore_missing = true
                      fields = [
                        "event.module",
                      ]
                    }
                  }
                ]
              })
            }
          }
        }
      }
    }
    }
  ]

  policy_map = { for idx, val in local.policies : val.name => val }
}

data "http" "winlogbeat-security-js" {
  url = "https://raw.githubusercontent.com/elastic/beats/${var.winlogbeat_version}/x-pack/winlogbeat/module/security/config/winlogbeat-security.js"
}

data "http" "winlogbeat-powershell-js" {
  url = "https://raw.githubusercontent.com/elastic/beats/${var.winlogbeat_version}/x-pack/winlogbeat/module/powershell/config/winlogbeat-powershell.js"
}

data "http" "winlogbeat-sysmon-js" {
  url = "https://raw.githubusercontent.com/elastic/beats/${var.winlogbeat_version}/x-pack/winlogbeat/module/sysmon/config/winlogbeat-sysmon.js"
}

// Write the request bodies to files so that they can be read by curl.
resource "local_file" "request-bodies" {
  for_each = local.policy_map

  content  = jsonencode(each.value)
  filename = "${path.module}/../../policy-${each.key}.json"
}

// Pretty format the request bodies for better readability.
resource "null_resource" "pretty-policies" {
  for_each = local.policy_map

  provisioner "local-exec" {
    command = <<EOT
jq -S . "${path.module}/../../policy-${each.key}.json" | sponge "${path.module}/../../policy-${each.key}.json"
EOT
  }

  depends_on = [local_file.request-bodies]
  triggers = {
    always_run = timestamp()
  }
}

// Generate a readme file.
resource "local_file" "readme" {
  content = templatefile("${path.module}/README.md.tftpl", {
    policy_map : { for idx, val in local.policies : val.name => jsonencode(val) }
    api_key : var.api_key,
    kibana_url : var.kibana_url,
    agent_policy_id : var.agent_policy_id,
    winlogbeat_version : var.winlogbeat_version,
    fleet_winlog_version : var.fleet_winlog_version,
    fleet_namespace : var.fleet_namespace,
  })
  filename = "${path.module}/../../README.md"
}