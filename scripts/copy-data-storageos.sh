#!/bin/bash

# Variables
VOLUME_NAME="nginx_config"
LOCAL_NGINX_DIR="/data/nginx"

# 1. Créer le volume StorageOS si non existant
if ! storageos volume inspect $VOLUME_NAME &>/dev/null; then
  echo "Creation du volume StorageOS $VOLUME_NAME..."
  storageos volume create --name=$VOLUME_NAME --size=1Gi --replica=2
else
  echo "Volume $VOLUME_NAME existe deja."
fi

# 2. Copier fichiers locaux dans volume StorageOS
echo "Copie des fichiers locaux vers le volume StorageOS..."
docker run --rm -v ${VOLUME_NAME}:/mnt -v ${LOCAL_NGINX_DIR}:/src busybox sh -c "cp -r /src/* /mnt/"

echo "Done."
