#!/bin/bash

KEYCLOAK_URL="http://localhost:8080"
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"
REALM="master"
TARGET_USERNAME="admin"
TARGET_ROLE="uma_authorization"
CONCURRENT_REQUESTS=20

echo "Step 1: Authenticating with Keycloak Admin API..."
TOKEN_RESPONSE=$(curl -s -X POST \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli" \
  -d "grant_type=password" \
  -d "username=${ADMIN_USERNAME}" \
  -d "password=${ADMIN_PASSWORD}")

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Failed to obtain access token"
  exit 1
fi

echo "Successfully authenticated"

echo ""
echo "Step 2: Looking up User ID for username: ${TARGET_USERNAME}..."
USER_RESPONSE=$(curl -s -X GET \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/users?username=${TARGET_USERNAME}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

USER_ID=$(echo "$USER_RESPONSE" | jq -r '.[0].id')

if [ -z "$USER_ID" ]; then
  echo "Failed to find user ID"
  exit 1
fi

echo "Found user ID: ${USER_ID}"

echo ""
echo "Step 3: Looking up role details for role: ${TARGET_ROLE}..."
ROLE_RESPONSE=$(curl -s -X GET \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/roles/${TARGET_ROLE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}")

if [ -z "$ROLE_RESPONSE" ]; then
  echo "Failed to fetch role details"
  exit 1
fi

echo "Found role details"

echo ""
echo "Step 4: Executing ${CONCURRENT_REQUESTS} concurrent role assignments with K6..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEYCLOAK_URL="$KEYCLOAK_URL" \
REALM="$REALM" \
USER_ID="$USER_ID" \
ACCESS_TOKEN="$ACCESS_TOKEN" \
ROLE_RESPONSE="$ROLE_RESPONSE" \
k6 run "$SCRIPT_DIR/assign-concurrently.js"

echo ""
echo "K6 test completed"

echo ""
echo "Step 5: Unassigning role..."
curl -s -X DELETE \
  "${KEYCLOAK_URL}/admin/realms/${REALM}/users/${USER_ID}/role-mappings/realm" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "[${ROLE_RESPONSE}]"
echo "Role unassigned"

echo ""
echo "Bug reproduction complete"
