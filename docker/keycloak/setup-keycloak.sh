#!/bin/bash
set -e

echo "Logging into Keycloak..."
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password secret

echo "Creating SolarBookshop realm..."
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh create realms \
  -s realm=SolarBookshop -s enabled=true || echo "Realm may already exist"

echo "Creating roles..."
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh create roles -r SolarBookshop \
  -s name=customer || echo "Role 'customer' may already exist"
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh create roles -r SolarBookshop \
  -s name=employee || echo "Role 'employee' may already exist"

echo "Creating users..."
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh create users -r SolarBookshop \
  -s username=ram \
  -s firstName=Ram \
  -s lastName=Lal \
  -s email=ram@solarbookshop.com \
  -s enabled=true || echo "User 'ram' may already exist"

docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh create users -r SolarBookshop \
  -s username=shayam \
  -s firstName=Shayam \
  -s lastName=Lal \
  -s email=shayam@solarbookshop.com \
  -s enabled=true || echo "User 'shayam' may already exist"

echo "Setting passwords..."
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh set-password -r SolarBookshop \
  --username ram --new-password secret
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh set-password -r SolarBookshop \
  --username shayam --new-password secret

echo "Assigning roles..."
# Ram is both customer and employee
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh add-roles -r SolarBookshop \
  --uusername ram --rolename customer --rolename employee

# Shyam is only customer
docker exec solar-keycloak /opt/keycloak/bin/kcadm.sh add-roles -r SolarBookshop \
  --uusername shayam --rolename customer

echo "Exporting realm..."
# Using kc.sh export to capture the realm configuration
# This way does not work in v26 due to some JDBC exception
docker exec solar-keycloak /opt/keycloak/bin/kc.sh export --file SolarBookshop-config.json --realm SolarBookshop
docker cp solar-keycloak:/opt/keycloak/SolarBookshop-config.json docker/keycloak/SolarBookshop-config.json

echo "Done! The realm data has been saved to docker/keycloak/SolarBookshop-config.json"

