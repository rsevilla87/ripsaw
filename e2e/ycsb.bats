#!/usr/bin/env bats

# vi: ft=bash

load helpers.bash

DETIK_CLIENT_NAMESPACE=benchmark-operator
export NAMESPACE=${DETIK_CLIENT_NAMESPACE}
indexes=(ripsaw-ycsb-summary ripsaw-ycsb-results)


@test "ycsb-mongo" {
  CR=ycsb/ycsb-mongo.yaml
  CR_NAME=$(get_benchmark_name ${CR})
  envsubst < ${CR} | kubectl apply -f -
  get_uuid ${CR_NAME}
  check_benchmark || die "Timeout waiting for benchmark/${CR_NAME} to complete"
  for index in ${indexes[@]}; do
    ES_INDEX=${index}
    check_es
  done
}

setup() {
  kubectl apply -n ${NAMESPACE} -f - <<< '
---
apiVersion: v1
kind: Service
metadata:
 name: mongo
 labels:
   name: mongo
spec:
 ports:
 - port: 27017
   targetPort: 27017
 clusterIP: None
 selector:
   role: mongo
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
 name: mongo
 namespace: benchmark-operator
spec:
 selector:
   matchLabels:
     role: mongo
 serviceName: "mongo"
 replicas: 1
 selector:
   matchLabels:
     role: mongo
 template:
   metadata:
     labels:
       role: mongo
       environment: test
   spec:
     terminationGracePeriodSeconds: 10
     containers:
     - name: mongo
       image: mongo
       command: ["/bin/sh"]
       args:  ["-c", "mkdir -p /tmp/data/db; mongod --bind_ip 0.0.0.0 --dbpath /tmp/data/db"]
       ports:
       - containerPort: 27017'
}
