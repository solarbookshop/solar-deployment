#!/bin/sh

printf "\n⌛ Destroying Kubernetes cluster...\n"

minikube stop --profile solar

minikube delete --profile solar

printf "\n🔥 Cluster destroyed\n"
