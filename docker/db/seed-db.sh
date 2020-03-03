#!/bin/bash
#
# Usage: $ ./seed-db.sh 

set -eu

echo "Seeding database ..."

readonly BASE_URL="http://${MARQUEZ_HOST}:${MARQUEZ_PORT}/api/v1"
echo "${BASE_URL}"

# NAMESPACES
cat ./data/namespaces.json | jq -c '.[]' | \
  while read -r i; do
    namespace=$(echo "${i}" | jq -r '.name')
    payload=$(echo "${i}" | jq -c '{ownerName: .ownerName, description: .description}')

    curl --silent --output /dev/null -X PUT "${BASE_URL}/namespaces/${namespace}" \
      -H 'Content-Type: application/json' \
      -d "${payload}"
  done

# SOURCES

cat ./data/sources.json | jq -c '.[]' | \
  while read -r i; do
    source=$(echo "${i}" | jq -r '.name')
    payload=$(echo "${i}" | jq -c '{type: .type, connectionUrl: .connectionUrl, description: .description}')

    curl --silent --output /dev/null -X PUT "${BASE_URL}/sources/${source}" \
      -H 'Content-Type: application/json' \
      -d "${payload}"
  done

# DATASETS

cat ./data/datasets.json | jq -c '.[]' | \
  while read -r i; do
    namespace=$(echo "${i}" | jq -r '.namespaceName')
    dataset=$(echo "${i}" | jq -r '.name')
    payload=$(echo "${i}" | jq -c '{type: .type, physicalName: .physicalName, sourceName: .sourceName, fields: .fields, description: .description}')

    curl --silent --output /dev/null -X PUT "${BASE_URL}/namespaces/${namespace}/datasets/${dataset}" \
      -H 'Content-Type: application/json' \
      -d "${payload}"
  done

# JOBS

cat ./data/jobs.json | jq -c '.[]' | \
  while read -r i; do
    namespace=$(echo "${i}" | jq -r '.namespaceName')
    job=$(echo "${i}" | jq -r '.name')
    payload=$(echo "${i}" | jq -c '{type: .type, inputs: .inputs, outputs: .outputs, location: .location, context: .context, description: .description}')

    curl --silent --output /dev/null -X PUT "${BASE_URL}/namespaces/${namespace}/jobs/${job}" \
      -H 'Content-Type: application/json' \
      -d "${payload}"
  done

# RUNS

cat ./data/runs.json | jq -c '.[]' | \
  while read -r i; do
    namespace=$(echo "${i}" | jq -r '.namespaceName')
    job=$(echo "${i}" | jq -r '.jobName')
    payload=$(echo "${i}" | jq -c '{runArgs: .runArgs}')

    response=$(curl --silent -X POST "${BASE_URL}/namespaces/${namespace}/jobs/${job}/runs" \
      -H 'Content-Type: application/json' \
      -d "${payload}")

    run_id=$(echo "${response}" | jq -r '.runId')
    run_states=( $(echo "${i}" | jq -r '.runStates[]') )
    for mark_run_as in "${run_states[@]}"; do
      curl --silent --output /dev/null -X POST "${BASE_URL}/jobs/runs/${run_id}/${mark_run_as}"
    done
  done

echo "DONE!"
