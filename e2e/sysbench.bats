#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

DETIK_CLIENT_NAMESPACE=benchmark-operator
export NAMESPACE=${DETIK_CLIENT_NAMESPACE}
ES_INDEX=ripsaw-sysbench-results


@test "sysbench-standard" {
  CR=sysbench/sysbench.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
}

setup_file() {
  basic_setup
}

teardown_file(){
  basic_teardown
}
