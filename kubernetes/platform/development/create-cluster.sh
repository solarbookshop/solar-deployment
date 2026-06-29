#!/bin/sh

printf "\n📦 Initializing Kubernetes cluster...\n"
minikube start --cpus 2 --memory 4g --driver docker --profile solar

printf "\n🔌 Enabling NGINX Ingress Controller...\n"
minikube addons enable ingress --profile solar

sleep 15

printf "\n📦 Deploying Keycloak..."
kubectl apply -f services/keycloak-config.yml
kubectl apply -f services/keycloak.yml

sleep 5

printf "\n⌛ Waiting for Keycloak to be deployed..."
while [ "$(kubectl get pod -l app=solar-keycloak | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for Keycloak to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=solar-keycloak \
  --timeout=300s

printf "\n📦 Deploying PostgreSQL......"
kubectl apply -f services/postgresql.yml

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

printf "\n📦 Deploying Redis......"
kubectl apply -f services/redis.yml

sleep 5

printf "\n⌛ Waiting for Redis to be deployed..."
while [ "$(kubectl get pod -l db=solar-redis | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for Redis to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=db=solar-redis \
  --timeout=180s

printf "\n📦 Deploying RabbitMQ......"
kubectl apply -f services/rabbitmq.yml

sleep 5

printf "\n⌛ Waiting for RabbitMQ to be deployed..."
while [ "$(kubectl get pod -l db=solar-rabbitmq | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for RabbitMQ to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=db=solar-rabbitmq \
  --timeout=180s

# minikube image load solar-ui:latest --profile solar
printf "\n📦 Deploying Solar UI..."
kubectl apply -f services/solar-ui.yml

sleep 5

printf "\n⌛ Waiting for Solar UI to be deployed..."
while [ "$(kubectl get pod -l app=solar-ui | wc -l)" -eq 0 ] ; do
  sleep 5
done

printf "\n⌛ Waiting for Solar UI to be ready..."
kubectl wait \
  --for=condition=ready pod \
  --selector=app=solar-ui \
  --timeout=180s

printf "\n⛵ Happy Sailing!\n"
