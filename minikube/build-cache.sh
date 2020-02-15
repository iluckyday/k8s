#!/bin/bash
set -e

minikube start --download-only=true --vm-driver=kvm2
ver=$(basename `ls -d $HOME/.minikube/cache/v*`)
tar -cJf /dev/shm/minikube-cache-$ver.tar.xz $HOME/.minikube/bin/ $HOME/.minikube/cache/