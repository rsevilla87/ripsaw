# vi: ft=bash

load "lib/utils"
load "lib/detik"

DETIK_CLIENT_NAME="kubectl"
DEBUG_DETIK="true"
uuid=""
suuid=""


setup_file() {
   kubectl delete ns ${NAMESPACE} --ignore-not-found
   debug "Deploying benchmark-operator"
   make -C ../ deploy
   kubectl rollout status deployment/benchmark-controller-manager
}

teardown_file() {
   debug "Tearing down benchmark-operator namespace"
   make -C ../ undeploy
   kubectl delete ns ${NAMESPACE} --ignore-not-found
}

setup(){
   export PROMETHEUS_TOKEN=$(oc sa get-token -n openshift-monitoring prometheus-k8s)
   export ES_SERVER=https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com
}

teardown() {
  debug "Deleting benchmark ${CR_NAME} from namespace ${NAMESPACE}"
  kubectl delete benchmark ${CR_NAME} -n ${NAMESPACE} --ignore-not-found
}

check_es() {
  debug "Looking for documents with uuid: ${uuid} in index ${ES_INDEX}"
  documents=$(curl -sS ${ES_SERVER}/${ES_INDEX}/_search?q=uuid.keyword:${uuid} | jq .hits.total.value)
  echo "Documents found: ${documents}"
  if [[ ${documents} -gt 0 ]]; then
    return 0
  else
    die "${documents} found in index ${ES_INDEX}"
  fi
}

get_uuid() {
  debug "Waiting for UUID from ${1}"
  local timeout=300
  while [[ ${timeout} -gt 0 ]]; do
    uuid=$(kubectl get benchmarks -n ${NAMESPACE} ${1} -o jsonpath="{.status.uuid}")
    if [[ -n ${uuid} ]]; then
      suuid=$(kubectl get benchmarks -n ${NAMESPACE} ${1} -o jsonpath="{.status.suuid}")
      break
    fi
    let timeout=$timeout-1
    sleep 1
  done
  if [[ ${timeout} -lt 0 ]]; then
    false
  fi
  debug "UUID from ${1}: ${uuid}"
  debug "Short UUID from ${1}: ${suuid}"
}


check_benchmark() {
  try "at most 40 times every 30s to find 1 benchmarks named '${CR_NAME}' with '.status.complete' being 'true'"
}

die() {
  kubectl get benchmark ${CR_NAME} -o yaml -n ${NAMESPACE} --ignore-not-found
  kubectl logs -l control-plane=controller-manager -c manager --tail=-1
  echo $1
  false
}

function get_benchmark_name() {
  benchmark_file=$1
  echo $(yq e '.metadata.name' $benchmark_file)
}
