#!/bin/sh

echo "\n⌛ Destroying Kubernetes cluster...\n"

minikube stop --profile solar

minikube delete --profile solar

echo "\n🔥 Cluster destroyed\n"
