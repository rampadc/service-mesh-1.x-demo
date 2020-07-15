#!/bin/bash

# Removes the demo from the cluster.  By default this will remove the Istio operators
set -u -o pipefail
declare -r SCRIPT_DIR=$(cd -P $(dirname $0) && pwd)
declare -r DEMO_HOME="$SCRIPT_DIR/.."
declare PROJECT_NAME="demo-app"
declare REMOVE_OPERATORS="true"
declare FORCE=""

while (( "$#" )); do
    case "$1" in
        -p|--project)
            PROJECT_NAME=$2
            shift 2
            ;;
        -f|--force)
            FORCE="true"
            shift 1
            ;;
        -k|--keep-operators)
            REMOVE_OPERATORS=""
            shift 1
            ;;
        -*|--*)
            echo "Error: Unsupported flag $1"
            exit 1
            ;;
        *) 
            break
    esac
done

# Assumes proxy has been setup
force-clean() {
    declare NAMESPACE=$1

    echo "Force removing project $NAMESPACE"

    oc get namespace $NAMESPACE -o json | jq '.spec = {"finalizers":[]}' > /tmp/temp.json
    curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/temp.json 127.0.0.1:8001/api/v1/namespaces/$NAMESPACE/finalize
    rm /tmp/temp.json
}

declare ISTIO_PRJ="${PROJECT_NAME}-istio-system"

# Delete all the projects
declare PROJECTS=( ${PROJECT_NAME} ${ISTIO_PRJ} )
for PROJECT in "${PROJECTS[@]}"; do
    oc get ns ${PROJECT} 2>/dev/null && oc delete project ${PROJECT}
done

if [[ "${REMOVE_OPERATORS}" ]]; then
    declare SUBS=( servicemesh jaeger kiali elastic-search )
    for SUB in "${SUBS[@]}"; do
        declare CSV=$(oc get sub/$SUB -o jsonpath='{.status.currentCSV}' -n openshift-operators)
        oc delete sub/$SUB -n openshift-operators
        oc delete csv/$CSV -n openshift-operators
    done
fi

declare PROXY_PID=""
if [[ ! -z "$FORCE" ]]; then
    echo -n "opening proxy"

    oc proxy &
    PROXY_PID=$!
fi

# wait until all projects are fully deleted
for PROJECT in "${PROJECTS[@]}"; do
    while [[ "$(oc get ns ${PROJECT} 2>/dev/null)" ]]; do

        if [[ ! -z "$FORCE" ]]; then
            force-clean "${PROJECT}"
        fi

        echo "Waiting for ${PROJECT} deletion."
        sleep 1
    done
done

# FIXME: Wait until all the operators are removed


if [[ ! -z "$PROXY_PID" ]]; then
    echo "closing proxy"
    kill $PROXY_PID
fi

