#!/usr/bin/env bash

set -euo pipefail

printf "\n📦 Installing ingress-nginx..."

kubectl apply -k resources

printf "\n📦 Installation completed.\n"