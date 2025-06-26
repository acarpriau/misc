#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Usage: $0 nodes_file NODE1 NODE2 [NODE3 ...]"
  echo "nodes_file format: VOLUME_NAME:BRICK_PATH par ligne"
  exit 1
fi

NODES_FILE=$1
shift
NODES=("$@")

if [ ! -f "$NODES_FILE" ]; then
  echo "Fichier $NODES_FILE non trouvé"
  exit 1
fi

echo "Noeuds utilisés : ${NODES[*]}"

while IFS=: read -r VOLUME_NAME BRICK_PATH
do
  if [[ -z "$VOLUME_NAME" || -z "$BRICK_PATH" ]]; then
    echo "Ligne ignorée (format incorrect) : $VOLUME_NAME:$BRICK_PATH"
    continue
  fi

  echo "Création du fichier $VOLUME_NAME.yml pour brick $BRICK_PATH"

  cat > "$VOLUME_NAME.yml" <<EOF
version: "3.8"

volumes:
  $VOLUME_NAME:
    driver: glusterfs
    driver_opts:
      volname: $VOLUME_NAME
      servers: "$(IFS=,; echo "${NODES[*]}")"
      path: "$BRICK_PATH"
EOF

done < "$NODES_FILE"

echo "Terminé."
