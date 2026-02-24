#!/usr/bin/env bash
set -euo pipefail

OUT_DIR=${OUT_DIR:-./data_local}
DT=${DT:-$(date +%F)}
TARGET_MB_LOGS=${TARGET_MB_LOGS:-256}
TARGET_MB_IOT=${TARGET_MB_IOT:-256}
CHUNK_LINES=${CHUNK_LINES:-200000}
mkdir -p "$OUT_DIR/$DT"

LOG_FILE="$OUT_DIR/$DT/logs_${DT//-/}.log"
IOT_FILE="$OUT_DIR/$DT/iot_${DT//-/}.jsonl"
TARGET_LOG_BYTES=$((TARGET_MB_LOGS * 1024 * 1024))
TARGET_IOT_BYTES=$((TARGET_MB_IOT * 1024 * 1024))

: > "$LOG_FILE"
: > "$IOT_FILE"

echo "[generate] DT=$DT"
echo "[generate] Objetivo logs: ${TARGET_MB_LOGS}MB"
echo "[generate] Objetivo iot : ${TARGET_MB_IOT}MB"
echo "[generate] Salida en: $OUT_DIR/$DT"

log_iter=0
while [ "$(wc -c < "$LOG_FILE")" -lt "$TARGET_LOG_BYTES" ]; do
  start=$((log_iter * CHUNK_LINES + 1))
  end=$(((log_iter + 1) * CHUNK_LINES))
  awk -v dt="$DT" -v s="$start" -v e="$end" '
    BEGIN {
      for (i=s; i<=e; i++) {
        if (i % 17 == 0) status=500
        else if (i % 7 == 0) status=404
        else status=200

        m=i % 5
        if (m == 0) action="LOGIN"
        else if (m == 1) action="READ"
        else if (m == 2) action="WRITE"
        else if (m == 3) action="UPDATE"
        else action="LOGOUT"

        printf "%sT%02d:%02d:%02dZ user=%06d action=%s status=%d latency_ms=%d src_ip=10.%d.%d.%d\n",
               dt, i%24, i%60, (i*7)%60, i%500000, action, status, (i*13)%900+10,
               i%255, (i*3)%255, (i*7)%255
      }
    }
  ' >> "$LOG_FILE"
  log_iter=$((log_iter + 1))
done

iot_iter=0
while [ "$(wc -c < "$IOT_FILE")" -lt "$TARGET_IOT_BYTES" ]; do
  start=$((iot_iter * CHUNK_LINES + 1))
  end=$(((iot_iter + 1) * CHUNK_LINES))
  awk -v dt="$DT" -v s="$start" -v e="$end" '
    BEGIN {
      for (i=s; i<=e; i++) {
        m=i % 4
        if (m == 0) { metric="temperature"; unit="C"; base=20.0 }
        else if (m == 1) { metric="humidity"; unit="pct"; base=50.0 }
        else if (m == 2) { metric="pressure"; unit="hPa"; base=1013.0 }
        else { metric="vibration"; unit="mm_s"; base=2.0 }

        value=base + ((i*17)%1000)/100.0
        printf "{\"deviceId\":\"dev-%06d\",\"ts\":\"%sT%02d:%02d:%02dZ\",\"metric\":\"%s\",\"value\":%.2f,\"unit\":\"%s\"}\n",
               i%800000, dt, i%24, i%60, (i*11)%60, metric, value, unit
      }
    }
  ' >> "$IOT_FILE"
  iot_iter=$((iot_iter + 1))
done

log_bytes=$(wc -c < "$LOG_FILE")
iot_bytes=$(wc -c < "$IOT_FILE")

echo "[generate] Generado: $LOG_FILE (${log_bytes} bytes)"
echo "[generate] Generado: $IOT_FILE (${iot_bytes} bytes)"
ls -lh "$OUT_DIR/$DT"
