#!/usr/bin/env bash

set -euo pipefail

printf "\n🐰 RabbitMQ deployment started."

printf "\n📦 Installing RabbitMQ Cluster Kubernetes Operator..."

printf "\n🧹 Removing stale RabbitMQ webhook configurations (if any)..."

kubectl delete mutatingwebhookconfiguration cluster-operator-mutating-webhook-configuration --ignore-not-found
kubectl delete validatingwebhookconfiguration cluster-operator-validating-webhook-configuration --ignore-not-found

kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/download/v2.9.0/cluster-operator.yml"

printf "\n⌛ Waiting for RabbitMQ Operator to be deployed..."

kubectl rollout status deployment/rabbitmq-cluster-operator \
  --timeout=300s \
  --namespace=rabbitmq-system

printf "\n⌛ Waiting for RabbitMQ Operator to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=rabbitmq-cluster-operator \
  --timeout=300s \
  --namespace=rabbitmq-system

printf "\n ✅ The RabbitMQ Cluster Kubernetes Operator has been successfully installed."

printf "\n-----------------------------------------------------"

printf "\n📦 Deploying RabbitMQ cluster..."

kubectl apply -f resources/cluster.yml

printf "\n⌛ Waiting for RabbitMQ cluster to be deployed..."

while [ "$(kubectl get pod -l app.kubernetes.io/name=solar-rabbitmq -n rabbitmq-system -o jsonpath='{.items[*].metadata.name}' | wc -w)" -eq 0 ] ; do
  sleep 15
done

printf "\n⌛ Waiting for RabbitMQ cluster to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=solar-rabbitmq \
  --timeout=600s \
  --namespace=rabbitmq-system

printf "\n✅ The RabbitMQ cluster has been successfully deployed."

printf "\n-----------------------------------------------------"

RABBITMQ_USERNAME=$(kubectl get secret solar-rabbitmq-default-user -o jsonpath='{.data.username}' -n=rabbitmq-system | base64 --decode)
export RABBITMQ_USERNAME
RABBITMQ_PASSWORD=$(kubectl get secret solar-rabbitmq-default-user -o jsonpath='{.data.password}' -n=rabbitmq-system | base64 --decode)
export RABBITMQ_PASSWORD

printf "\nUsername: %s" "$RABBITMQ_USERNAME"
printf "\nPassword: %s" "$RABBITMQ_PASSWORD"

printf "\n🔑 Generating Secret with RabbitMQ credentials."

kubectl delete secret solar-rabbitmq-credentials || true

kubectl create secret generic solar-rabbitmq-credentials \
    --from-literal=spring.rabbitmq.host=solar-rabbitmq.rabbitmq-system.svc.cluster.local \
    --from-literal=spring.rabbitmq.port=5672 \
    --from-literal=spring.rabbitmq.username="$RABBITMQ_USERNAME" \
    --from-literal=spring.rabbitmq.password="$RABBITMQ_PASSWORD"

unset RABBITMQ_USERNAME
unset RABBITMQ_PASSWORD

printf "\n🍃 Secret 'solar-rabbitmq-credentials' has been created for Spring Boot applications to interact with RabbitMQ."

printf "\n🐰 RabbitMQ deployment completed.\n"