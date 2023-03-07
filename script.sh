#!/bin/bash

## run  playbooks
ansible-playbook -i inventory/inventory.yaml playbooks/playbook-agent.yaml 
ansible-playbook -i inventory/inventory.yaml playbooks/playbook-kubernetes.yaml 

## set default storage
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

## config metallb pool
kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e 's/strictARP: false/strictARP: true/' | kubectl apply -f - -n kube-system
kubectl apply -f yaml-files/metallb.yaml

## add gitrepo
kubectl apply -f yaml-files/gitrepository.yaml
## add helmrelease
kubectl apply -f yaml-files/helmrelease.yaml

## set ingress for gitlab & registry
kubectl get ingress gitlab-webservice-default -o yaml | sed -e 's/gitlab.mahsa-monem.maxtld.dev/gitlab-mahsa-monem.maxtld.dev/' | kubectl apply -f - 
kubectl get ingress gitlab-registry -o yaml | sed -e 's/registry.mahsa-monem.maxtld.dev/gitlab-registry-monem.maxtld.dev/' | kubectl apply -f - 

