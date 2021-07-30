#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

DETIK_CLIENT_NAMESPACE=benchmark-operator
export NAMESPACE=${DETIK_CLIENT_NAMESPACE}
ES_INDEX=ripsaw-uperf-results


@test "uperf-standard" {
  CR=uperf/uperf.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}


@test "uperf-resources" {
  CR=uperf/uperf_resources.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}


@test "uperf-network policy" {
  CR=uperf/uperf_networkpolicy.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}


@test "uperf-serviceip" {
  CR=uperf/uperf_serviceip.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}
