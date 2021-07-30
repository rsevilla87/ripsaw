# vi: ft=bash

load "lib/utils"
load "lib/detik"

DETIK_CLIENT_NAME="kubectl"
DEBUG_DETIK="true"
uuid=""
suuid=""
ARTIFACTS_DIR=artifacts


setup_file() {
  export PROMETHEUS_TOKEN=$(oc sa get-token -n openshift-monitoring prometheus-k8s)
  export ES_SERVER=https://search-perfscale-dev-chmf5l4sh66lvxbnadi4bznl3a.us-west-2.es.amazonaws.com
  kubectl delete ns ${NAMESPACE} --ignore-not-found
  echo "Deploying benchmark-operator"
  make -C ../ deploy
  kubectl -n ${NAMESPACE} rollout status deployment/benchmark-controller-manager
}

teardown_file() {
  echo "Tearing down benchmark-operator namespace"
  make -C ../ undeploy
  kubectl delete ns ${NAMESPACE} --ignore-not-found
}

teardown() {
  kubectl delete benchmark ${CR_NAME} -n ${NAMESPACE} --ignore-not-found
}

check_es() {
  if [[ -n ${indexes} ]]; then
    for index in ${indexes[@]}; do
      echo "Looking for documents with uuid: ${uuid} in index ${index}"
      documents=$(curl -sS ${ES_SERVER}/${index}/_search?q=uuid.keyword:${uuid} | jq .hits.total.value)
      if [[ ${documents} -le 0 ]]; then
        die "${documents} documents found in index ${ES_INDEX}"
      fi
    done
  else
    echo "Looking for documents with uuid: ${uuid} in index ${ES_INDEX}"
    documents=$(curl -sS ${ES_SERVER}/${ES_INDEX}/_search?q=uuid.keyword:${uuid} | jq .hits.total.value)
    if [[ ${documents} -le 0 ]]; then
      die "${documents} documents found in index ${ES_INDEX}"
    fi
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
  timeout -k ${1} ${1} bash -c "
  until [[ $(kubectl -n ${NAMESPACE} get benchmark/${CR_NAME} -o jsonpath={.status.complete}) == 'true' ]]; do
    sleep 10
  done
  "
}

die() {
  echo $1
  mkdir -p ${ARTIFACTS_DIR}/${CR_NAME}
  kubectl get benchmark ${CR_NAME} -o yaml -n ${NAMESPACE} --ignore-not-found > ${ARTIFACTS_DIR}/${CR_NAME}/${CR_NAME}.yaml
  kubectl -n ${NAMESPACE} logs deployment/benchmark-controller-manager --tail=-1 -c manager > ${ARTIFACTS_DIR}/${CR_NAME}/benchmark-controller-manager.log
  for pod in $(kubectl get pod -l benchmark-uuid=${uuid} -o custom-columns="name:.metadata.name" --no-headers); do
    log_file=${ARTIFACTS_DIR}/${CR_NAME}/${pod}.log
    echo "Saving log from pod ${pod} in ${log_file}"
    kubectl -n ${NAMESPACE} logs --tail=-1 ${pod} > ${log_file}
  done
  false
}

function get_benchmark_name() {
  benchmark_file=$1
  echo $(yq e '.metadata.name' $benchmark_file)
}
