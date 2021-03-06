#!/bin/bash
set -e

minikube start --download-only=true --vm-driver=kvm2
ver=$(basename `ls -d $HOME/.minikube/cache/v*`)
cd $HOME
rm -rf .minikube/cache/images/k8s.gcr.io
tar -czf /dev/shm/minikube-cache-$ver.tar.gz .minikube/bin/ .minikube/cache/
ls -lh /dev/shm/minikube-cache-$ver.tar.gz
