terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "0.5.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "3.2.1"
    }

    elasticstack = {
      source  = "elastic/elasticstack"
      version = "0.5.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.3.0"
    }
  }
}

// API key is read from EC_API_KEY.
provider "ec" {
  endpoint = "https://staging.found.no"
}

provider "elasticstack" {
  elasticsearch {
    endpoints = [ec_deployment.fleet-winlog.elasticsearch[0].https_endpoint]
    username  = ec_deployment.fleet-winlog.elasticsearch_username
    password  = ec_deployment.fleet-winlog.elasticsearch_password
  }
}

resource "ec_deployment" "fleet-winlog" {
  name = "fleet-winlog-7x-policy-${var.env_id}"

  region                 = "gcp-us-central1"
  version                = var.stack_version
  deployment_template_id = "gcp-general-purpose"

  elasticsearch {
    topology {
      id         = "hot_content"
      zone_count = 1
      size       = "1g"
    }
  }

  kibana {
    topology {
      size = "1g"
    }
  }

  integrations_server {}
}

// Fetch the fleet server URL from the Fleet API.
data "http" "fleet-settings" {
  url = "${ec_deployment.fleet-winlog.kibana[0].https_endpoint}/api/fleet/settings"

  # Optional request headers
  request_headers = {
    Accept        = "application/json"
    Authorization = "Basic ${base64encode("${ec_deployment.fleet-winlog.elasticsearch_username}:${ec_deployment.fleet-winlog.elasticsearch_password}")}"
  }
}

locals {
  basic_auth = format("Basic %s", base64encode(format("%s:%s", ec_deployment.fleet-winlog.elasticsearch_username, ec_deployment.fleet-winlog.elasticsearch_password)))

  kibana_url = ec_deployment.fleet-winlog.kibana[0].https_endpoint

  fleet_server_url = jsondecode(data.http.fleet-settings.response_body).item.fleet_server_hosts[0]
}

resource "elasticstack_elasticsearch_security_api_key" "count-reader" {
  name = "count_reader"

  role_descriptors = jsonencode({
    count_reader = {
      indices = [
        {
          names      = ["logs-winlog.*"],
          privileges = ["read"]
        }
      ]
    }
  })

  expiration = "1h"

  metadata = jsonencode({
    "env" = "testing"
  })
}
