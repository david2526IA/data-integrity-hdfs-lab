#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
TARGET_REPLICATION=${TARGET_REPLICATION:-2}
OUT_DIR=${OUT_DIR:-./outputs/recovery/$DT}

mkdir -p "$OUT_DIR"

echo "[recovery] DT=$DT"
echo "[recovery] TARGET_REPLICATION=$TARGET_REPLICATION"

stopped_dns=$(docker ps -a --filter "status=exited" --format '{{.Names}}' | grep -E 'dnnm|datanode' || true)
if [ -n "$stopped_dns" ]; then
  while IFS= read -r dn; do
    [ -z "$dn" ] && continue
    echo "[recovery] Iniciando DataNode detenido: $dn"
    docker start "$dn" > /dev/null
  done <<< "$stopped_dns"
fi

sleep 10

docker exec "$NN_CONTAINER" bash -lc "hdfs dfsadmin -report" > "$OUT_DIR/after_restart_report.txt" || true

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -setrep -R -w $TARGET_REPLICATION /data" > "$OUT_DIR/setrep_output.txt" 2>&1 || true

docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  if hdfs dfs -test -d /backup/logs/raw/dt=$DT; then
    hdfs dfs -rm -r -f /data/logs/raw/dt=$DT || true
    hdfs dfs -cp /backup/logs/raw/dt=$DT /data/logs/raw/
  fi
  if hdfs dfs -test -d /backup/iot/raw/dt=$DT; then
    hdfs dfs -rm -r -f /data/iot/raw/dt=$DT || true
    hdfs dfs -cp /backup/iot/raw/dt=$DT /data/iot/raw/
  fi
" || true

docker exec "$NN_CONTAINER" bash -lc "hdfs fsck /data -files -blocks -locations" > "$OUT_DIR/fsck_data_after_recovery.txt" || true
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /data | sed -n '1,120p'" > "$OUT_DIR/data_ls_after_recovery.txt" || true
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -du -h /data | sed -n '1,40p'" > "$OUT_DIR/data_du_after_recovery.txt" || true

if grep -qi "Status: HEALTHY" "$OUT_DIR/fsck_data_after_recovery.txt"; then
  recovery_status="HEALTHY"
else
  recovery_status="NOT_HEALTHY"
fi

{
  echo "dt=$DT"
  echo "target_replication=$TARGET_REPLICATION"
  echo "recovery_status=$recovery_status"
} > "$OUT_DIR/recovery_summary.txt"

tmp_container="/tmp/recovery_${DT}"
docker exec "$NN_CONTAINER" bash -lc "rm -rf $tmp_container && mkdir -p $tmp_container"
docker cp "$OUT_DIR/." "$NN_CONTAINER:$tmp_container/"
docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /audit/incidents/$DT
  hdfs dfs -mkdir -p /audit/fsck/$DT
  hdfs dfs -put -f $tmp_container/* /audit/incidents/$DT/
  hdfs dfs -put -f $tmp_container/fsck_data_after_recovery.txt /audit/fsck/$DT/
"

echo "[recovery] Resumen:"
cat "$OUT_DIR/recovery_summary.txt"
