#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 NODE1 NODE2 [NODE3 ...]"
  exit 1
fi

NODES=("$@")
VOLUME_NAME="nginx_config_vol"
BRICK_PATH="/data/nginx_config"
REPLICA_COUNT=${#NODES[@]}

echo "Noeuds : ${NODES[*]}"
echo "Volume : $VOLUME_NAME"
echo "Brick path : $BRICK_PATH"
echo "Replica count : $REPLICA_COUNT"

# 1. Installer glusterfs-server sur tous les nœuds
echo "==> Installation de GlusterFS sur tous les nœuds"
for node in "${NODES[@]}"; do
  echo "=> Installation sur $node"
  ssh "$node" "sudo apt-get update && sudo apt-get install -y glusterfs-server && sudo systemctl enable glusterd && sudo systemctl start glusterd"
done

# 2. Créer le répertoire brick sur chaque nœud
echo "==> Création du dossier brick $BRICK_PATH sur tous les nœuds"
for node in "${NODES[@]}"; do
  ssh "$node" "sudo mkdir -p $BRICK_PATH && sudo chown -R \$(whoami):\$(whoami) $BRICK_PATH"
done

# 3. Peering GlusterFS : ajouter chaque pair depuis le premier nœud
echo "==> Peering des nœuds GlusterFS"
for node in "${NODES[@]:1}"; do
  ssh "${NODES[0]}" "sudo gluster peer probe $node"
done

# Vérification des pairs
ssh "${NODES[0]}" "sudo gluster peer status"

# 4. Créer et démarrer le volume répliqué
echo "==> Création et démarrage du volume GlusterFS"
brick_list=""
for node in "${NODES[@]}"; do
  brick_list+="$node:$BRICK_PATH "
done

ssh "${NODES[0]}" "sudo gluster volume create $VOLUME_NAME replica $REPLICA_COUNT $brick_list force"
ssh "${NODES[0]}" "sudo gluster volume start $VOLUME_NAME"
ssh "${NODES[0]}" "sudo gluster volume info"

echo "==> GlusterFS configuré avec succès."

# 5. Installer le plugin GlusterFS Docker (si nécessaire)
echo "==> Installer le plugin Docker GlusterFS sur tous les nœuds"
for node in "${NODES[@]}"; do
  ssh "$node" "docker plugin install gluster/glusterfs-volume-plugin --grant-all-permissions || echo 'Plugin déjà installé ou erreur ignorée'"
done

# 6. Créer un fichier docker-compose.yml pour la déclaration du volume

cat > $VOLUME_NAME.yml <<EOF
version: "3.8"

volumes:
  $VOLUME_NAME:
    driver: glusterfs
    driver_opts:
      volname: $VOLUME_NAME
      servers: "$(IFS=,; echo "${NODES[*]}")"
      path: ""
EOF

echo "==> Fichier $VOLUME_NAME.yml créé avec succès."
