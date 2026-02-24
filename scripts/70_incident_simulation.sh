#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
INCIDENT_WAIT_SEC=${INCIDENT_WAIT_SEC:-15}
OUT_DIR=${OUT_DIR:-./outputs/incident/$DT}
TARGET_DN=${TARGET_DN:-}

mkdir -p "$OUT_DIR"

if [ -z "$TARGET_DN" ]; then
  TARGET_DN=$(docker ps --format '{{.Names}}' | grep -E 'dnnm|datanode' | head -n 1 || true)
fi

if [ -z "$TARGET_DN" ]; then
  echo "[incident] ERROR: no se encontro DataNode activo para simular incidente."
  exit 1
fi

echo "[incident] DT=$DT"
echo "[incident] DataNode objetivo=$TARGET_DN"
echo "[incident] Se detendra el DataNode y se capturara impacto."

docker exec "$NN_CONTAINER" bash -lc "hdfs dfsadmin -report" > "$OUT_DIR/before_report.txt" || true

start_utc=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
docker stop "$TARGET_DN" > "$OUT_DIR/stop_output.txt"
sleep "$INCIDENT_WAIT_SEC"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfsadmin -report" > "$OUT_DIR/during_report.txt" || true
docker exec "$NN_CONTAINER" bash -lc "hdfs fsck /data -files -blocks -locations" > "$OUT_DIR/during_fsck_data.txt" || true

{
  echo "dt=$DT"
  echo "start_utc=$start_utc"
  echo "target_dn=$TARGET_DN"
  echo "wait_seconds=$INCIDENT_WAIT_SEC"
  echo "action=docker stop $TARGET_DN"
  echo "note=El DataNode queda detenido para que 80_recovery_restore.sh demuestre recuperacion."
} > "$OUT_DIR/incident_summary.txt"

tmp_container="/tmp/incident_${DT}"
docker exec "$NN_CONTAINER" bash -lc "rm -rf $tmp_container && mkdir -p $tmp_container"
docker cp "$OUT_DIR/." "$NN_CONTAINER:$tmp_container/"
docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /audit/incidents/$DT
  hdfs dfs -put -f $tmp_container/* /audit/incidents/$DT/
"

echo "[incident] Incidente simulado y evidencias guardadas en $OUT_DIR"
