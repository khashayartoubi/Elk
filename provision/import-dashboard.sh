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

echo 'Kibana metric dashboard provisioned.'
