#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

DETIK_CLIENT_NAMESPACE=benchmark-operator
export NAMESPACE=${DETIK_CLIENT_NAMESPACE}
indexes=(ripsaw-smallfile-results ripsaw-smallfile-rsptimes)


@test "smallfile-standard" {
  CR=smallfile/smallfile.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  for index in ${indexes[@]}; do
    ES_INDEX=${index}
    check_es
  done
}

@test "smallfile-hostpath" {
  CR=smallfile/smallfile_hostpath.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  for index in ${indexes[@]}; do
    ES_INDEX=${index}
    check_es
  done
}
