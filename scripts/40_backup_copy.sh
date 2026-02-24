#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
OUT_DIR=${OUT_DIR:-./outputs/backup/$DT}

echo "[backup] DT=$DT"
mkdir -p "$OUT_DIR"

docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /backup/logs/raw/dt=$DT
  hdfs dfs -mkdir -p /backup/iot/raw/dt=$DT
  if hdfs dfs -test -d /data/logs/raw/dt=$DT; then
    hdfs dfs -cp -f /data/logs/raw/dt=$DT/* /backup/logs/raw/dt=$DT/
  fi
  if hdfs dfs -test -d /data/iot/raw/dt=$DT; then
    hdfs dfs -cp -f /data/iot/raw/dt=$DT/* /backup/iot/raw/dt=$DT/
  fi
"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /backup | sed -n '1,80p'" > "$OUT_DIR/backup_ls.txt"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -du -h /backup | sed -n '1,40p'" > "$OUT_DIR/backup_du.txt"

tmp_container="/tmp/backup_copy_${DT}"
docker exec "$NN_CONTAINER" bash -lc "rm -rf $tmp_container && mkdir -p $tmp_container"
docker cp "$OUT_DIR/." "$NN_CONTAINER:$tmp_container/"
docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /audit/inventory/$DT
  hdfs dfs -put -f $tmp_container/* /audit/inventory/$DT/
"

echo "[backup] Copia completada. Evidencias locales en $OUT_DIR"
