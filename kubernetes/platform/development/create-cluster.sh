#!/bin/sh

printf "\n📦 Initializing Kubernetes cluster...\n"

minikube start --cpus 2 --memory 4g --driver docker --profile solar

printf "\n🔌 Enabling NGINX Ingress Controller...\n"

minikube addons enable ingress --profile solar

sleep 15

printf "\n📦 Deploying platform services..."

kubectl apply -f services

sleep 5

printf "\n⌛ Waiting for PostgreSQL to be deployed..."

while [ "$(kubectl get pod -l db=solar-postgres | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for PostgreSQL to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=solar-postgres \
  --timeout=180s

printf "\n⌛ Waiting for Redis to be deployed..."

while [ "$(kubectl get pod -l db=solar-redis | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for Redis to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=solar-redis \
  --timeout=180s

printf "\n⌛ Waiting for RabbitMQ to be deployed..."

while [ "$(kubectl get pod -l db=solar-rabbitmq | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for RabbitMQ to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=db=solar-rabbitmq \
  --timeout=180s

printf "\n⛵ Happy Sailing!\n"
