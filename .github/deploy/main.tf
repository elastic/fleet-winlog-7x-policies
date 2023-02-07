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
  }
}

// API key is read from EC_API_KEY.
provider "ec" {
  endpoint = "https://staging.found.no"
}

provider "elasticstack" {
  kibana {
    url      = ec_deployment.fleet-demo.kibana[0].https_endpoint
    username = ec_deployment.fleet-demo.elasticsearch_username
    password = ec_deployment.fleet-demo.elasticsearch_password
  }
}

resource "ec_deployment" "fleet-demo" {
  name = "fleet-winlog-7x-policy-test"

  region                 = "gcp-us-central1"
  version                = "8.6.1"
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
  url = "${ec_deployment.fleet-demo.kibana[0].https_endpoint}/api/fleet/settings"

  # Optional request headers
  request_headers = {
    Accept        = "application/json"
    Authorization = "Basic ${base64encode("${ec_deployment.fleet-demo.elasticsearch_username}:${ec_deployment.fleet-demo.elasticsearch_password}")}"
  }
}

locals {
  basic_auth = format("Basic %s", base64encode(format("%s:%s", ec_deployment.fleet-demo.elasticsearch_username, ec_deployment.fleet-demo.elasticsearch_password)))

  kibana_url = ec_deployment.fleet-demo.kibana[0].https_endpoint

  fleet_server_url = jsondecode(data.http.fleet-settings.response_body).item.fleet_server_hosts[0]
}