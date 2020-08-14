#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMP_DIR=${SCRIPT_DIR}/temp
RESULT=0

export CHANGE_MINIKUBE_NONE_USER=true

errorExit () {
    echo; echo "ERROR: $1"
    exit 1
}

warn () {
    echo; echo "WARNING: $1"; echo
}

title () {
    echo
    echo "-----------------------------------------------------"
    printf "| %-50s|\n" "$1"
    echo "-----------------------------------------------------"
}

verifyLinux () {
    if [ $(uname) != Linux ]; then
        errorExit "This script can run on Linux only!"
    fi
}

validateSudo () {
    if [ ${EUID} != 0 ]; then
        errorExit "This script must be run as root or with sudo"
    fi
}

setup () {
    verifyLinux
    validateSudo
    mkdir -p ${TEMP_DIR}
}

installTools () {
    title "Installing tools"

    echo "kubectl"
    if ! kubectl --help > /dev/null 2>&1; then
        echo "Downloading kubectl"
        curl -# -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v1.9.0/bin/linux/amd64/kubectl && \
            chmod +x kubectl && \
            mv kubectl /usr/local/bin/
    else
        echo "kubectl already exists"
    fi

    echo "helm"
    if ! helm --help > /dev/null 2>&1; then
        echo "Downloading helm"
        curl -# -o ${TEMP_DIR}/helm-v2.9.1-linux-amd64.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz && \
            tar -xzf ${TEMP_DIR}/helm-v2.9.1-linux-amd64.tar.gz -C ${TEMP_DIR} && \
            chmod +x ${TEMP_DIR}/linux-amd64/helm && \
            mv ${TEMP_DIR}/linux-amd64/helm /usr/local/bin/
    else
        echo "helm already exists"
    fi
}

lintChart () {
    title "Helm lint test"

    helm lint ${SCRIPT_DIR}/demo || errorExit "helm lint failed"

    echo "SUCCESS"
}

startMinikube () {
    title "Setting up Minikube"

    # Download minikube.
    if ! minikube --help > /dev/null 2>&1; then
    echo "Downloading minikube"
        curl -# -Lo minikube https://storage.googleapis.com/minikube/releases/v0.25.2/minikube-linux-amd64 && \
            chmod +x minikube && \
            mv minikube /usr/local/bin/
    else
        echo "minikube already exists"
    fi

    echo "Starting minikube"
    minikube start --vm-driver=none --kubernetes-version=v1.9.0 || errorExit "minikube start failed"

    # Fix the kubectl context, as it's often stale.
    minikube update-context || errorExit "minikube update-context failed"

    echo "Waiting for Kubernetes to be ready"
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
    until kubectl get nodes -o jsonpath="${JSONPATH}" 2>&1 | grep -q "Ready=True"; do
        sleep 2
    done

    # Show cluster info
    kubectl cluster-info || errorExit "kubectl cluster-info failed"
}

getPodName () {
    local search_string=$1
    [ -n ${search_string} ] || errorExit "Must pass search_string"

    local namespace=$2
    if [ -z "${namespace}" ]; then
        namespace=default
    fi

    local name=$(kubectl get pods -a -o=name -n ${namespace} | grep  ${search_string} | awk -F'/' '{print $2}')

    echo -n ${name}
}

waitForPod () {
    local pod_name=$1
    [ -n ${pod_name} ] || errorExit "Must pass pod name"

    local namespace=$2
    if [ -z "${namespace}" ]; then
        namespace=default
    fi

    echo "Waiting for pod $pod_name to get to state Running"
    local pod_status=

    while [ "$pod_status" != "Running" ]; do
        pod_status=$(kubectl get pod -n ${namespace} ${pod_name} 2> /dev/null | grep ${pod_name} | awk '{print $3}')
        sleep 2
        echo -n "."
    done
    echo
}

setupHelm () {
    title "Setup helm"

    helm init || errorExit "helm init failed"

    echo "Getting tiller pod name"
    local pod_name=$(getPodName tiller kube-system)

    echo "Waiting for pod ${pod_name}"
    waitForPod ${pod_name} kube-system

    sleep 10
}

deployChart () {
    title "Deploying helm chart"

    echo "Helm install"
    helm upgrade --install demo --set service.type=NodePort ${SCRIPT_DIR}/demo || errorExit "helm install failed"

    echo "Getting pod name"
    local pod_name=$(getPodName demo)

    echo "Waiting for pod ${pod_name}"
    waitForPod ${pod_name}

    sleep 5
}

testApplication () {
    title "Testing Demo application"

    echo "Getting node ip and port for demo service"
    local node_ip=$(kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")
    local node_port=$(kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services demo)

    echo "Service demo node port is ${node_port}"

    local url=http://${node_ip}:${node_port}

    # A plain curl to the service to see output (debug)
    echo "Verbose curl -v ${url}"
    echo -----------
    curl -v ${url}
    echo -----------

    echo "Testing http code for ${url}"
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" ${url})

    echo "Response code is ${response_code}"
    if [ "${response_code}" == 200 ]; then
        echo "SUCCESS"
        RESULT=0
    else
        echo "FAILED"
        RESULT=1
    fi
}

############## Main

setup
installTools
lintChart
startMinikube
setupHelm
deployChart
testApplication

exit ${RESULT}
