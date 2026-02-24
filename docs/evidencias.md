# Evidencias de ejecucion

Fecha base de ejecucion reproducible: `2026-02-23`

## 1) NameNode UI (9870)

Capturas:

- C02 - NameNode Live Nodes  
  ![C02 - NameNode Live Nodes](capturas_evidencias/c02_namenode_live_nodes.png)
- C03 - Capacidad HDFS en UI  
  ![C03 - Capacidad HDFS](capturas_evidencias/c03_capacidad_hdfs.png)

Comando equivalente usado:

```bash
docker exec namenode bash -lc "hdfs dfsadmin -report | sed -n '1,120p'"
```

## 2) Auditoria fsck

Capturas:

- C09 - Ejecucion auditoria fsck  
  ![C09 - Auditoria fsck](capturas_evidencias/c09_auditoria_fsck.png)
- C10 - fsck detallado (bloques/locations)  
  ![C10 - fsck detallado 1](capturas_evidencias/c10_fsck_detallado_1.png)
- C10.5 - fsck detallado adicional  
  ![C10.5 - fsck detallado 2](capturas_evidencias/c10_5_fsck_detallado_2.png)
- C11 - Resumen fsck CSV  
  ![C11 - Resumen fsck CSV](capturas_evidencias/c11_resumen_fsck_csv.png)

Resumen obtenido:

```csv
target,corrupt_count,missing_count,under_replicated_count,status
/data,0,0,0,HEALTHY
/backup,0,0,0,HEALTHY
```

Ficheros generados:

- `outputs/fsck/2026-02-23/fsck_data.txt`
- `outputs/fsck/2026-02-23/fsck_backup.txt`
- `outputs/fsck/2026-02-23/fsck_summary.csv`

Tambien subido a HDFS:

- `/audit/fsck/2026-02-23/`

## 3) Backup + validacion

Capturas:

- C12 - Backup copiado  
  ![C12 - Backup copiado](capturas_evidencias/c12_backup_copiado.png)
- C13 - Validacion inventario  
  ![C13 - Validacion inventario](capturas_evidencias/c13_validacion_inventario.png)
- C14 - Browse `/backup` en UI  
  ![C14 - Browse backup UI](capturas_evidencias/c14_browse_backup_ui.png)

Resumen obtenido:

```text
dt=2026-02-23
ok_count=2
missing_in_backup_count=0
size_mismatch_count=0
extra_in_backup_count=0
```

Ficheros generados:

- `outputs/backup/2026-02-23/backup_ls.txt`
- `outputs/backup/2026-02-23/backup_du.txt`
- `outputs/inventory/2026-02-23/data_inventory.csv`
- `outputs/inventory/2026-02-23/backup_inventory.csv`
- `outputs/inventory/2026-02-23/inventory_compare.csv`
- `outputs/inventory/2026-02-23/inventory_summary.txt`

Tambien subido a HDFS:

- `/audit/inventory/2026-02-23/`

## 4) Incidente + recuperacion

Incidente ejecutado:

- `docker stop clustera-dnnm-3`

Capturas:

- C15 - Incidente simulado  
  ![C15 - Incidente simulado](capturas_evidencias/c15_incidente_simulado.png)
- C16 - Resumen del incidente  
  ![C16 - Evidencia del incidente](capturas_evidencias/c16_incidente_reporte.png)
- C17 - Recuperacion  
  ![C17 - Recuperacion](capturas_evidencias/c17_recuperacion.png)

Resumen recuperacion:

```text
dt=2026-02-23
target_replication=2
recovery_status=HEALTHY
```

Ficheros generados:

- `outputs/incident/2026-02-23/before_report.txt`
- `outputs/incident/2026-02-23/during_report.txt`
- `outputs/incident/2026-02-23/during_fsck_data.txt`
- `outputs/incident/2026-02-23/incident_summary.txt`
- `outputs/recovery/2026-02-23/after_restart_report.txt`
- `outputs/recovery/2026-02-23/fsck_data_after_recovery.txt`
- `outputs/recovery/2026-02-23/recovery_summary.txt`

Tambien subido a HDFS:

- `/audit/incidents/2026-02-23/`

## 5) Metricas y coste

Capturas:

- C19 - `docker stats` en vivo durante operacion  
  ![C19 - Docker stats](capturas_evidencias/c19_metricas_docker_stats.png)

Tablas:

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

```csv
replication,duration_seconds
1,21.28
2,11.29
3,21.23
```

Ficheros generados:

- `outputs/metrics/2026-02-23/step_times.csv`
- `outputs/metrics/2026-02-23/replication_experiment.csv`
- `outputs/metrics/2026-02-23/docker_stats_snapshot.txt`
- `outputs/metrics/2026-02-23/docker_stats_rep1.txt`
- `outputs/metrics/2026-02-23/docker_stats_rep2.txt`
- `outputs/metrics/2026-02-23/docker_stats_rep3.txt`

## 6) Galeria completa (orden cronologico)

- C01 - Cluster levantado  
  ![C01 - Cluster levantado](capturas_evidencias/c01_cluster_levantado.png)
- C02 - NameNode Live Nodes  
  ![C02 - NameNode Live Nodes](capturas_evidencias/c02_namenode_live_nodes.png)
- C03 - Capacidad HDFS  
  ![C03 - Capacidad HDFS](capturas_evidencias/c03_capacidad_hdfs.png)
- C04 - Parametros HDFS (R2)  
  ![C04 - Parametros HDFS](capturas_evidencias/c04_parametros_hdfs_r2.png)
- C04.5 - Parametros HDFS (detalle)  
  ![C04.5 - Parametros HDFS detalle](capturas_evidencias/c04_5_parametros_hdfs_r2_detalle.png)
- C05 - Bootstrap (estructura HDFS)  
  ![C05 - Bootstrap](capturas_evidencias/c05_bootstrap_estructura_hdfs.png)
- C06 - Generacion de dataset  
  ![C06 - Generacion de dataset](capturas_evidencias/c06_generacion_dataset.png)
- C07 - Ingesta HDFS (`ls -R`)  
  ![C07 - Ingesta ls -R](capturas_evidencias/c07_ingesta_hdfs_ls_r.png)
- C08 - Ingesta HDFS (`du -h`)  
  ![C08 - Ingesta du -h](capturas_evidencias/c08_ingesta_hdfs_du_h.png)
- C09 - Auditoria fsck  
  ![C09 - Auditoria fsck](capturas_evidencias/c09_auditoria_fsck.png)
- C10 - fsck detallado  
  ![C10 - fsck detallado](capturas_evidencias/c10_fsck_detallado_1.png)
- C10.5 - fsck detallado adicional  
  ![C10.5 - fsck detallado adicional](capturas_evidencias/c10_5_fsck_detallado_2.png)
- C11 - Resumen fsck CSV  
  ![C11 - Resumen fsck](capturas_evidencias/c11_resumen_fsck_csv.png)
- C12 - Backup copiado  
  ![C12 - Backup copiado](capturas_evidencias/c12_backup_copiado.png)
- C13 - Validacion inventario  
  ![C13 - Validacion inventario](capturas_evidencias/c13_validacion_inventario.png)
- C14 - Browse backup UI  
  ![C14 - Browse backup UI](capturas_evidencias/c14_browse_backup_ui.png)
- C15 - Incidente simulado  
  ![C15 - Incidente simulado](capturas_evidencias/c15_incidente_simulado.png)
- C16 - Evidencia incidente (report)  
  ![C16 - Evidencia incidente](capturas_evidencias/c16_incidente_reporte.png)
- C17 - Recuperacion  
  ![C17 - Recuperacion](capturas_evidencias/c17_recuperacion.png)
- C19 - Metricas docker stats  
  ![C19 - Metricas docker stats](capturas_evidencias/c19_metricas_docker_stats.png)

Capturas adicionales:

- Extra 01  
  ![Extra 01](capturas_evidencias/extra_01_pantallazo_051101.png)
- Extra 02  
  ![Extra 02](capturas_evidencias/extra_02_pantallazo_051116.png)
- Extra 03  
  ![Extra 03](capturas_evidencias/extra_03_pantallazo_051134.png)
