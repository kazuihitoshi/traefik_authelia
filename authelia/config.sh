#!/bin/sh
set -e
SECRET_FILE=/config/.generated_secrets
USERS_FILE=/config/users_database.yml
if [ ! -f "${SECRET_FILE}" ]; then
  echo "Generating new secrets..."
  JWT_SECRET=$(authelia crypto rand --length 128 --charset alphanumeric|awk '{print $NF}')
  STORAGE_KEY=$(authelia crypto rand --length 128 --charset alphanumeric|awk '{print $NF}')
cat <<EOF > "${SECRET_FILE}"
JWT_SECRET='${JWT_SECRET}'
STORAGE_KEY='${STORAGE_KEY}'
EOF
fi
. "${SECRET_FILE}"
if [ ! -f "${USERS_FILE}" ];then
  cp /config/users_database.template.yml "${USERS_FILE}"
fi
cat <<EOF > /config/config.auto.yml
totp:
  issuer: "${AUTHELIA_ISSUER}"
session:
  cookies:
    - domain: "${DOMAIN}"
      authelia_url: "https://${AUTH_DOMAIN}"
jwt_secret: "${JWT_SECRET}"
storage:
  encryption_key: "${STORAGE_KEY}"
  local:
    path: "/config/db.sqlite3"
access_control:
  default_policy: deny    # basically refuse
  rules:
    - domain: "*.${DOMAIN}"
      policy: two_factor  # enforce two-factor authentication on all subdomains
authentication_backend:
  file:
    path: "${USERS_FILE}"
    watch: true
EOF
