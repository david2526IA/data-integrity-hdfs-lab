#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
RETRIES=${RETRIES:-30}
SLEEP_SEC=${SLEEP_SEC:-2}

echo "[bootstrap] DT=$DT"

if ! docker ps --format '{{.Names}}' | grep -qx "$NN_CONTAINER"; then
  echo "[bootstrap] ERROR: contenedor '$NN_CONTAINER' no esta levantado."
  echo "[bootstrap] Levanta el cluster con: cd docker/clusterA && docker compose up -d --scale dnnm=3"
  exit 1
fi

echo "[bootstrap] Esperando a HDFS..."
attempt=1
until docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls / >/dev/null 2>&1"; do
  if [ "$attempt" -ge "$RETRIES" ]; then
    echo "[bootstrap] ERROR: HDFS no responde tras $RETRIES intentos."
    exit 1
  fi
  sleep "$SLEEP_SEC"
  attempt=$((attempt + 1))
done

docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /data/logs/raw/dt=$DT
  hdfs dfs -mkdir -p /data/iot/raw/dt=$DT
  hdfs dfs -mkdir -p /backup/logs/raw/dt=$DT
  hdfs dfs -mkdir -p /backup/iot/raw/dt=$DT
  hdfs dfs -mkdir -p /audit/fsck/$DT
  hdfs dfs -mkdir -p /audit/inventory/$DT
  hdfs dfs -mkdir -p /audit/incidents/$DT
"

echo "[bootstrap] Estructura HDFS creada."
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /data | sed -n '1,40p'"
