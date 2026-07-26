#!/usr/bin/env bash

set -euo pipefail

printf "\n📦 Deploying Solar UI..."

kubectl apply -f resources

printf "⌛ Waiting for Solar UI to be deployed..."

while [ "$(kubectl get pod -l app=solar-ui | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for Solar UI to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app=solar-ui \
  --timeout=180s

printf "\n📦 Solar UI deployment completed.\n"