# Evidencias de ejecucion

Fecha base de ejecucion reproducible: `2026-02-23`

## 1) NameNode UI (9870)

Pendiente de captura manual (tu parte):

- Captura de `Datanodes -> Live Nodes` mostrando 3 DataNodes vivos.
- Captura de capacidad usada/libre del cluster.

Comando equivalente (ya verificado):

```bash
docker exec namenode bash -lc "hdfs dfsadmin -report | sed -n '1,120p'"
```

## 2) Auditoria fsck

Evidencias generadas:

- `outputs/fsck/2026-02-23/fsck_data.txt`
- `outputs/fsck/2026-02-23/fsck_backup.txt`
- `outputs/fsck/2026-02-23/fsck_summary.csv`

Resumen obtenido:

```csv
target,corrupt_count,missing_count,under_replicated_count,status
/data,0,0,0,HEALTHY
/backup,0,0,0,HEALTHY
```

Tambien subido a HDFS en:

- `/audit/fsck/2026-02-23/`

## 3) Backup + validacion

Evidencias generadas:

- `outputs/backup/2026-02-23/backup_ls.txt`
- `outputs/backup/2026-02-23/backup_du.txt`
- `outputs/inventory/2026-02-23/data_inventory.csv`
- `outputs/inventory/2026-02-23/backup_inventory.csv`
- `outputs/inventory/2026-02-23/inventory_compare.csv`
- `outputs/inventory/2026-02-23/inventory_summary.txt`

Resumen obtenido:

```text
dt=2026-02-23
ok_count=2
missing_in_backup_count=0
size_mismatch_count=0
extra_in_backup_count=0
```

Tambien subido a HDFS en:

- `/audit/inventory/2026-02-23/`

## 4) Incidente + recuperacion

Incidente ejecutado:

- `docker stop clustera-dnnm-3`

Evidencias generadas:

- `outputs/incident/2026-02-23/before_report.txt`
- `outputs/incident/2026-02-23/during_report.txt`
- `outputs/incident/2026-02-23/during_fsck_data.txt`
- `outputs/incident/2026-02-23/incident_summary.txt`
- `outputs/recovery/2026-02-23/after_restart_report.txt`
- `outputs/recovery/2026-02-23/fsck_data_after_recovery.txt`
- `outputs/recovery/2026-02-23/recovery_summary.txt`

Resumen recuperacion:

```text
dt=2026-02-23
target_replication=2
recovery_status=HEALTHY
```

Tambien subido a HDFS en:

- `/audit/incidents/2026-02-23/`

## 5) Metricas

Evidencias generadas:

- `outputs/metrics/2026-02-23/step_times.csv`
- `outputs/metrics/2026-02-23/replication_experiment.csv`
- `outputs/metrics/2026-02-23/docker_stats_snapshot.txt`
- `outputs/metrics/2026-02-23/docker_stats_rep1.txt`
- `outputs/metrics/2026-02-23/docker_stats_rep2.txt`
- `outputs/metrics/2026-02-23/docker_stats_rep3.txt`

Tiempos del pipeline:

```csv
step,duration_seconds
00_bootstrap.sh,10
10_generate_data.sh,15
20_ingest_hdfs.sh,46
30_fsck_audit.sh,8
40_backup_copy.sh,13
50_inventory_compare.sh,6
70_incident_simulation.sh,62
80_recovery_restore.sh,31
```

Experimento de replicacion:

```csv
replication,duration_seconds
1,21.28
2,11.29
3,21.23
```

Pendiente de captura manual (tu parte):

- Captura de `docker stats` durante una operacion activa (por ejemplo `setrep -w 3` o `backup_copy`).

## 6) Capturas obligatorias que faltan (checklist final)

- [ ] NameNode UI con `Live Nodes`.
- [ ] NameNode UI navegando `/data`.
- [ ] NameNode UI navegando `/backup`.
- [ ] `docker stats` en vivo durante operacion.
