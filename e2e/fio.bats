#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

DETIK_CLIENT_NAMESPACE=benchmark-operator
export NAMESPACE=${DETIK_CLIENT_NAMESPACE}
ES_INDEX=ripsaw-fio-results


@test "standard" {
  CR=fio/valid_fio.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

@test "bsrange" {
  CR=fio/valid_fio_bsrange.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es 
}

@test "hostpath" {
  CR=fio/valid_fio_hostpath.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f - 
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  check_es
}

@test "ocs-cachedrop" {
  CR=fio/valid_fio_ocs_cache_drop.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  openshift_storage_present=$(oc get namespace | awk '/openshift-storage/' | wc -l)
  if [ $openshift_storage_present -gt 0 ]; then
    kubectl label nodes -l node-role.kubernetes.io/worker= kernel-cache-dropper=yes --overwrite
    kubectl patch OCSInitialization ocsinit -n openshift-storage --type json --patch \
      '[{ "op": "replace", "path": "/spec/enableCephTools", "value": true }]'
    drop_cache_pods=$(oc -n openshift-storage get pod | awk '/drop/' | awk '/unning/' | wc -l)
    if [ $drop_cache_pods -eq 0 ] ; then
      kubectl create -f ../resources/ceph_osd_cache_drop/rook_ceph_drop_cache_pod.yaml
      kubectl wait --for=condition=Initialized pods/rook-ceph-osd-cache-drop -n openshift-storage --timeout=100s
    fi
    sleep 5
	envsubst < ${CR} | kubectl apply -f - 
    get_uuid ${CR_NAME}
    check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
    check_es
  fi
}
