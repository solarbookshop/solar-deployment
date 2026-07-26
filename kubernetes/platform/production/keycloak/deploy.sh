#!/usr/bin/env bash

set -euo pipefail

printf "\n🗝️  Keycloak deployment started.\n"

printf "📦 Installing Keycloak..."

clientSecret=$(echo $ random | openssl md5 | head -c 20)

kubectl apply -f resources/namespace.yml
sed "s/solar-keycloak-secret/$clientSecret/" resources/keycloak-config.yml | kubectl apply -f -

printf "\n📦 Configuring Helm chart..."

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install solar-keycloak bitnami/keycloak \
  --values values.yml \
  --namespace keycloak-system \
  --version 21.4.1

printf "\n⌛ Waiting for Keycloak to be deployed..."

sleep 15

while [ "$(kubectl get pod -l app.kubernetes.io/component=keycloak -n keycloak-system | wc -l)" -eq 0 ] ; do
  sleep 15
done

printf "\n⌛ Waiting for Keycloak to be ready..."

kubectl wait \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=keycloak \
  --timeout=600s \
  --namespace=keycloak-system

printf "\n✅  Keycloak cluster has been successfully deployed."

printf "\n🔐 Your Keycloak Admin credentials..."

printf "\n Admin Username: user"
printf "\n Admin Password: %s" "$(kubectl get secret --namespace keycloak-system solar-keycloak -o jsonpath="{.data.admin-password}" | base64 --decode)"

printf "\n🔑 Generating Secret with Keycloak client secret."

kubectl delete secret solar-keycloak-client-credentials || true

kubectl create secret generic solar-keycloak-client-credentials \
    --from-literal=spring.security.oauth2.client.registration.keycloak.client-secret="$clientSecret"

printf "\n🍃 A 'solar-keycloak-client-credentials' has been created for Spring Boot applications to interact with Keycloak."

printf "\n🗝️  Keycloak deployment completed.\n"
