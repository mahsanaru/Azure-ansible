#!/bin/bash

## run  playbooks
ansible-playbook -i inventory/inventory.yaml playbooks/playbook-agent.yaml 
ansible-playbook -i inventory/inventory.yaml playbooks/playbook-kubernetes.yaml 

## set default storage
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

## config metallb pool
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e 's/strictARP: false/strictARP: true/' | kubectl apply -f - -n kube-system
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.254.10.146/32
EOF


## add ingress for gitlab
cat <<EOF | kubectl create -f -

## add helmrelease
cat <<EOF | kubectl create -f -
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: weather-app
  namespace: server
spec:
  interval: 1m
  install:
    createNamespace: true
  chart:
    spec:
      chart: ./charts/weather-app
      sourceRef:
        kind: GitRepository
        name: flux-system
        namespace: flux-system
      interval: 1m
EOF

## set ingress for gitlab & registry
kubectl get ingress gitlab-webservice-default -o yaml | sed -e 's/gitlab.mahsa-monem.maxtld.dev/gitlab-mahsa-monem.maxtld.dev/' | kubectl apply -f - 
kubectl get ingress gitlab-registry -o yaml | sed -e 's/registry.mahsa-monem.maxtld.dev/gitlab-registry-monem.maxtld.dev/' | kubectl apply -f - 

