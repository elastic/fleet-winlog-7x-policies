# Generate Module

This Terraform module generates the request bodies for the Fleet package policies API.

1. It fetches the javascript definition of the Winlogbeat 7.x modules.
2. Build a package policy request body for each of the Windows event log channels
in the Winlogbeat modules.
3. Output request bodies as JSON.
4. "Pretty" format the JSON.
5. Output the readme file.

## Maintenance

The `fleet_winlog_version` variable should be updated to test with the latest release
of the winlog integration package.

The `winlogbeat_version` variable should be updated to pull Winlogbeat module definitions
from the latest 7.x release.