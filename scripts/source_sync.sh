#!/bin/bash
set -eo pipefail

# Directory where WordPress is deployed
DEPLOY_DIR="/var/www/html/wordpress/"
SOURCE_DIR="/var/www/html/source/dest/"

# source sync
echo "Starting source sync..."
rsync -avzc --delete --exclude='.*' \
  --exclude artifact.zip \
  --exclude wp-config.php \
  --exclude wp-content/uploads/ \
  "${SOURCE_DIR}" "${DEPLOY_DIR}"

echo "Starting post-deploy cleanup..."

## Remove the deployment artifact if it exists
#if [ -d "${SOURCE_DIR}" ]; then
#  rm -rf "${SOURCE_DIR}"
#  echo "Removed artifact"
#fi

# Reset ownership and permissions
echo "Setting correct ownership and permissions..."
chown -R ec2-user:www-data "${DEPLOY_DIR}"
chown -R nginx:www-data "${DEPLOY_DIR}wp-content/uploads"
find "${DEPLOY_DIR}" -type d -exec chmod 775 {} \;
find "${DEPLOY_DIR}" -type f -exec chmod 644 {} \;

echo "Cleanup completed successfully."