#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
OUT_DIR=${OUT_DIR:-./outputs/fsck/$DT}

echo "[fsck] DT=$DT"
mkdir -p "$OUT_DIR"

docker exec "$NN_CONTAINER" bash -lc "hdfs fsck /data -files -blocks -locations" > "$OUT_DIR/fsck_data.txt" || true

has_backup=0
if docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -test -d /backup"; then
  docker exec "$NN_CONTAINER" bash -lc "hdfs fsck /backup -files -blocks -locations" > "$OUT_DIR/fsck_backup.txt" || true
  has_backup=1
fi

extract_metric() {
  local file="$1"
  local pattern="$2"
  local raw
  raw=$(grep -Eim1 "$pattern" "$file" || true)
  if [ -z "$raw" ]; then
    echo "0"
    return
  fi
  echo "$raw" | sed -E 's/.*:[[:space:]]*([0-9]+).*/\1/'
}

status_for_file() {
  local file="$1"
  if grep -qi "Status: HEALTHY" "$file"; then
    echo "HEALTHY"
  else
    echo "NOT_HEALTHY"
  fi
}

summary_csv="$OUT_DIR/fsck_summary.csv"
echo "target,corrupt_count,missing_count,under_replicated_count,status" > "$summary_csv"

data_corrupt=$(extract_metric "$OUT_DIR/fsck_data.txt" "Corrupt blocks|CORRUPT files")
data_missing=$(extract_metric "$OUT_DIR/fsck_data.txt" "Missing blocks|MISSING blocks")
data_under=$(extract_metric "$OUT_DIR/fsck_data.txt" "Under-replicated blocks|Under replicated blocks")
data_status=$(status_for_file "$OUT_DIR/fsck_data.txt")
echo "/data,$data_corrupt,$data_missing,$data_under,$data_status" >> "$summary_csv"

if [ "$has_backup" -eq 1 ]; then
  backup_corrupt=$(extract_metric "$OUT_DIR/fsck_backup.txt" "Corrupt blocks|CORRUPT files")
  backup_missing=$(extract_metric "$OUT_DIR/fsck_backup.txt" "Missing blocks|MISSING blocks")
  backup_under=$(extract_metric "$OUT_DIR/fsck_backup.txt" "Under-replicated blocks|Under replicated blocks")
  backup_status=$(status_for_file "$OUT_DIR/fsck_backup.txt")
  echo "/backup,$backup_corrupt,$backup_missing,$backup_under,$backup_status" >> "$summary_csv"
fi

tmp_container="/tmp/fsck_audit_${DT}"
docker exec "$NN_CONTAINER" bash -lc "rm -rf $tmp_container && mkdir -p $tmp_container"
docker cp "$OUT_DIR/." "$NN_CONTAINER:$tmp_container/"
docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /audit/fsck/$DT
  hdfs dfs -put -f $tmp_container/* /audit/fsck/$DT/
"

echo "[fsck] Resumen:"
cat "$summary_csv"
echo "[fsck] Evidencias subidas a /audit/fsck/$DT"
