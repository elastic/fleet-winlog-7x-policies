# Using Winlogbeat 7.x script processors with the Fleet winlog integration

This project demonstrates how to use the Fleet API to add
[winlog integrations][winlog_integration] to a Fleet agent policy.
It will add a winlog input for each of the four Windows event log channels
described in the [Winlogbeat 7.x][winlogbeat_modules].
module documentation. It incorporates the Beats `script` processor logic
from the respective Winlogbeat module into the Agent policy.

Assumptions:

- Winlogbeat module scripts are from version v7.17.10.
- Fleet winlog integration [version][winlog_changelog] is 1.16.0.
- The "default" data stream namespace is used for all data streams.
- Each Windows event log channel is configured with its own data stream (e.g. logs-winlog.security-default).
- The mappings of the Fleet winlog integration are applied to the data.
- The listed commands are executed from a directory containing the `policy-*.json`
files contained in this repository.

[winlog_integration]: https://docs.elastic.co/en/integrations/winlog
[winlog_changelog]: https://docs.elastic.co/en/integrations/winlog#changelog
[winlogbeat_modules]: https://www.elastic.co/guide/en/beats/winlogbeat/7.17/winlogbeat-modules.html

Pre-requirements:
1. Record the ID of a Fleet agent policy to which you want the winlog
integration added. We'll set this as `AGENT_POLICY_ID` in our shell environment.
2. Obtain an Elasticsearch API key that can manage Fleet. We'll set this as
`API_KEY` in our shell environment.
3. Get the URL to Kibana. We'll set this as `KIBANA_URL` in our shell environment.

If you run all four of the `curl` commands below on an empty Fleet agent policy
then this will be the end result when viewing the policy.

![Resulting Policy](https://i.imgur.com/zdVWM3x.png)

## winlog-powershell-operational

This will add a new integration named `winlog-powershell-operational` in your Agent policy.

```sh
# Substitute in your own environment variable values.
export API_KEY="exampleZWUJHTHZPZHRHMnlfci06Y3ByU0Jva1hUYWEwQmR0NzVZRlpSQQ=="
export AGENT_POLICY_ID="87323640-a676-11ed-b7ad-57c2b61f1488"
export KIBANA_URL="https://localhost:5601"

curl \
  -XPOST \
  --fail-with-body \
  --header 'Content-Type: application/json' \
  --header 'kbn-xsrf: true' \
  --header "Authorization: ApiKey $API_KEY" \
  "$KIBANA_URL/api/fleet/package_policies" \
  -d @<(cat policy-winlog-powershell-operational.json | envsubst)
```
## winlog-security

This will add a new integration named `winlog-security` in your Agent policy.

```sh
# Substitute in your own environment variable values.
export API_KEY="exampleZWUJHTHZPZHRHMnlfci06Y3ByU0Jva1hUYWEwQmR0NzVZRlpSQQ=="
export AGENT_POLICY_ID="87323640-a676-11ed-b7ad-57c2b61f1488"
export KIBANA_URL="https://localhost:5601"

curl \
  -XPOST \
  --fail-with-body \
  --header 'Content-Type: application/json' \
  --header 'kbn-xsrf: true' \
  --header "Authorization: ApiKey $API_KEY" \
  "$KIBANA_URL/api/fleet/package_policies" \
  -d @<(cat policy-winlog-security.json | envsubst)
```
## winlog-sysmon

This will add a new integration named `winlog-sysmon` in your Agent policy.

```sh
# Substitute in your own environment variable values.
export API_KEY="exampleZWUJHTHZPZHRHMnlfci06Y3ByU0Jva1hUYWEwQmR0NzVZRlpSQQ=="
export AGENT_POLICY_ID="87323640-a676-11ed-b7ad-57c2b61f1488"
export KIBANA_URL="https://localhost:5601"

curl \
  -XPOST \
  --fail-with-body \
  --header 'Content-Type: application/json' \
  --header 'kbn-xsrf: true' \
  --header "Authorization: ApiKey $API_KEY" \
  "$KIBANA_URL/api/fleet/package_policies" \
  -d @<(cat policy-winlog-sysmon.json | envsubst)
```
## winlog-windows-powershell

This will add a new integration named `winlog-windows-powershell` in your Agent policy.

```sh
# Substitute in your own environment variable values.
export API_KEY="exampleZWUJHTHZPZHRHMnlfci06Y3ByU0Jva1hUYWEwQmR0NzVZRlpSQQ=="
export AGENT_POLICY_ID="87323640-a676-11ed-b7ad-57c2b61f1488"
export KIBANA_URL="https://localhost:5601"

curl \
  -XPOST \
  --fail-with-body \
  --header 'Content-Type: application/json' \
  --header 'kbn-xsrf: true' \
  --header "Authorization: ApiKey $API_KEY" \
  "$KIBANA_URL/api/fleet/package_policies" \
  -d @<(cat policy-winlog-windows-powershell.json | envsubst)
```
