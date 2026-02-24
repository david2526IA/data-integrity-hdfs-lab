# DataSecure Lab - Integridad de Datos en Big Data (HDFS)

Proyecto practico de integridad de datos sobre Hadoop en Docker.

- Enunciado: `docs/enunciado_proyecto.md`
- Rubrica: `docs/rubric.md`
- Entrega: `docs/entrega.md`
- Evidencias: `docs/evidencias.md`

## Quickstart (reproducible)

Recomendado (3 DataNodes):

```bash
cd docker/clusterA
docker compose up -d --scale dnnm=3

DT=2026-02-23 NN_CONTAINER=namenode bash scripts/00_bootstrap.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/10_generate_data.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/20_ingest_hdfs.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/30_fsck_audit.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/40_backup_copy.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/50_inventory_compare.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/70_incident_simulation.sh
DT=2026-02-23 NN_CONTAINER=namenode bash scripts/80_recovery_restore.sh
```

El compose incluye un ajuste para `dnnm` que limpia metadata local de DataNode al arrancar, evitando errores de `Incompatible clusterIDs` entre reinicios.

## Servicios

- NameNode UI: http://localhost:9870
- ResourceManager UI: http://localhost:8088
- Jupyter: http://localhost:8889

## Parametros HDFS (R2)

Ubicacion de configuracion dentro del NameNode:

- `HADOOP_CONF_DIR=/opt/bd/hadoop/etc/hadoop/`
- XML principal: `/opt/bd/hadoop/etc/hadoop/hdfs-site.xml`

Valores efectivos:

- `dfs.blocksize = 64m`
- `dfs.replication = 3`

Justificacion tecnica (coste vs integridad):

1. `dfs.replication=3` tolera la caida de hasta 2 DataNodes sin perdida inmediata de disponibilidad del bloque.
2. Esa replicacion mejora resiliencia frente a fallos de disco, red o nodo durante ingesta y copia.
3. El coste directo es mas uso de red y almacenamiento (aprox. 3x logico para datos replicados).
4. En este laboratorio se dispone de 3 DataNodes, por lo que `3` es alcanzable y coherente para datos sensibles.
5. `dfs.blocksize=64m` reduce overhead de metadata frente a bloques pequenos y mantiene paralelismo razonable.
6. Un bloque de 64 MB acelera operaciones secuenciales y evita exceso de objetos por fichero grande.
7. Para ficheros de cientos de MB, 64 MB permite ver claramente el reparto de bloques y replicas en fsck.
8. CRC por bloque en HDFS detecta corrupcion a nivel de almacenamiento y transporte interno.
9. Hashes de aplicacion (sha256/md5) complementan la verificacion end-to-end entre origen y destino.
10. Recomendacion final: mantener `replication=3` para datos criticos y reducir a `2` solo si prima coste.

## Artefactos generados

- Evidencias locales: `outputs/`
- Auditorias HDFS: `/audit/fsck/<DT>/`
- Inventarios HDFS: `/audit/inventory/<DT>/`
- Incidentes/recuperacion: `/audit/incidents/<DT>/`

## Notebook

- `notebooks/03_metricas_y_conclusiones.ipynb`: tabla de auditoria, tiempos y recomendaciones.

## Entrega individual

Requisitos clave:

1. Fork en tu cuenta GitHub.
2. Todo en rama `main`.
3. Tag obligatorio `v1.0-entrega`.
4. Entregar URL del fork (y opcionalmente release del tag).
