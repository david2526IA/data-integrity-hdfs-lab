#!/usr/bin/env bash
set -euo pipefail

NN_CONTAINER=${NN_CONTAINER:-namenode}
DT=${DT:-$(date +%F)}
OUT_DIR=${OUT_DIR:-./outputs/inventory/$DT}

echo "[inventory] DT=$DT"
mkdir -p "$OUT_DIR"

docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /data | sed -n '1,100000p'" > "$OUT_DIR/data_ls.txt"
docker exec "$NN_CONTAINER" bash -lc "hdfs dfs -ls -R /backup | sed -n '1,100000p'" > "$OUT_DIR/backup_ls.txt"

awk '$1 ~ /^-/ {print $8","$5}' "$OUT_DIR/data_ls.txt" | sort > "$OUT_DIR/data_inventory.csv"
awk '$1 ~ /^-/ {print $8","$5}' "$OUT_DIR/backup_ls.txt" | sort > "$OUT_DIR/backup_inventory.csv"

awk -F, '{p=$1; sub("^/data/","/backup/",p); print p","$2}' "$OUT_DIR/data_inventory.csv" | sort > "$OUT_DIR/data_inventory_as_backup.csv"

tmp_compare="$OUT_DIR/inventory_compare_unsorted.csv"

awk -F, '
  NR==FNR {src[$1]=$2; next}
  {dst[$1]=$2}
  END {
    print "path,status,source_size,dest_size"
    for (p in src) {
      if (!(p in dst)) print p",MISSING_IN_BACKUP,"src[p]","
      else if (src[p] != dst[p]) print p",SIZE_MISMATCH,"src[p]","dst[p]
      else print p",OK,"src[p]","dst[p]
    }
    for (p in dst) {
      if (!(p in src)) print p",EXTRA_IN_BACKUP,,"dst[p]
    }
  }
' "$OUT_DIR/data_inventory_as_backup.csv" "$OUT_DIR/backup_inventory.csv" > "$tmp_compare"

{
  head -n 1 "$tmp_compare"
  tail -n +2 "$tmp_compare" | sort
} > "$OUT_DIR/inventory_compare.csv"

ok_count=$(awk -F, 'NR>1 && $2=="OK" {c++} END {print c+0}' "$OUT_DIR/inventory_compare.csv")
missing_count=$(awk -F, 'NR>1 && $2=="MISSING_IN_BACKUP" {c++} END {print c+0}' "$OUT_DIR/inventory_compare.csv")
mismatch_count=$(awk -F, 'NR>1 && $2=="SIZE_MISMATCH" {c++} END {print c+0}' "$OUT_DIR/inventory_compare.csv")
extra_count=$(awk -F, 'NR>1 && $2=="EXTRA_IN_BACKUP" {c++} END {print c+0}' "$OUT_DIR/inventory_compare.csv")

{
  echo "dt=$DT"
  echo "ok_count=$ok_count"
  echo "missing_in_backup_count=$missing_count"
  echo "size_mismatch_count=$mismatch_count"
  echo "extra_in_backup_count=$extra_count"
} > "$OUT_DIR/inventory_summary.txt"

tmp_container="/tmp/inventory_compare_${DT}"
docker exec "$NN_CONTAINER" bash -lc "rm -rf $tmp_container && mkdir -p $tmp_container"
docker cp "$OUT_DIR/." "$NN_CONTAINER:$tmp_container/"
docker exec "$NN_CONTAINER" bash -lc "
  set -euo pipefail
  hdfs dfs -mkdir -p /audit/inventory/$DT
  hdfs dfs -put -f $tmp_container/* /audit/inventory/$DT/
"

echo "[inventory] Resumen:"
cat "$OUT_DIR/inventory_summary.txt"
echo "[inventory] Evidencias en $OUT_DIR y /audit/inventory/$DT"
