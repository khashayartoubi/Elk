#!/bin/bash
set -euo pipefail

# Import only the host and Docker-resource dashboard. This intentionally does
# not create, query, delete, or modify any log dashboards or log documents.
until curl -fsS -u "${KIBANA_LOGIN_USER}:${KIBANA_LOGIN_PASSWORD}" \
  http://kibana:5601/api/status >/dev/null; do
  sleep 3
done

curl -fsS -u "${KIBANA_LOGIN_USER}:${KIBANA_LOGIN_PASSWORD}" \
  -H 'kbn-xsrf: elk-dashboard-provisioner' \
  -F 'file=@/provision/observability.ndjson' \
  'http://kibana:5601/api/saved_objects/_import?overwrite=true' >/dev/null

# Legacy aggregation visualizations have a Kibana-side bucket cap. Keep it
# above the dashboard terms aggregation so every monitored container is shown.
curl -fsS -u "${KIBANA_LOGIN_USER}:${KIBANA_LOGIN_PASSWORD}" \
  -H 'kbn-xsrf: elk-dashboard-provisioner' \
  -H 'Content-Type: application/json' \
  -X PUT "http://kibana:5601/api/saved_objects/config/${STACK_VERSION}" \
  -d '{"attributes":{"visualization:terms:bucket:limit":1000}}' >/dev/null

echo 'Kibana metric dashboard provisioned.'
