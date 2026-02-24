#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
LOCAL_DIR=${LOCAL_DIR:-./data_local/$DT}
LOG_FILE="$LOCAL_DIR/logs_${DT//-/}.log"
IOT_FILE="$LOCAL_DIR/iot_${DT//-/}.jsonl"
TMP_IN_CONTAINER="/tmp/data_integrity_ingest/$DT"

echo "[ingest] DT=$DT"
echo "[ingest] Local dir=$LOCAL_DIR"

if [ ! -f "$LOG_FILE" ] || [ ! -f "$IOT_FILE" ]; then
  echo "[ingest] ERROR: no se encuentran los ficheros esperados en '$LOCAL_DIR'."
  echo "[ingest] Esperados:"
  echo "  - $LOG_FILE"
  echo "  - $IOT_FILE"
  echo "[ingest] Ejecuta primero: bash scripts/10_generate_data.sh"
  exit 1
fi

docker exec "$NN_CONTAINER" bash -lc "mkdir -p $TMP_IN_CONTAINER"
docker cp "$LOG_FILE" "$NN_CONTAINER:$TMP_IN_CONTAINER/"
docker cp "$IOT_FILE" "$NN_CONTAINER:$TMP_IN_CONTAINER/"

docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /data/logs/raw/dt=$DT
  hdfs dfs -mkdir -p /data/iot/raw/dt=$DT
  hdfs dfs -put -f $TMP_IN_CONTAINER/logs_${DT//-/}.log /data/logs/raw/dt=$DT/
  hdfs dfs -put -f $TMP_IN_CONTAINER/iot_${DT//-/}.jsonl /data/iot/raw/dt=$DT/
"

echo "[ingest] Carga a HDFS completada."
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /data | sed -n '1,80p'"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -du -h /data | sed -n '1,40p'"
