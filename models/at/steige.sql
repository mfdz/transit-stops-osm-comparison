MODEL (
  name at.steige,
  kind FULL,
  tags at,
  columns (
    FID TEXT,
    stg_id TEXT,
    hst_id TEXT,
    stg_name TEXT,
    stg_globid TEXT,
    stg_x DOUBLE,
    stg_y DOUBLE,
    umst_vm TEXT,
    umst_max TEXT,
    gis_vm TEXT,
    linien TEXT,
    geom TEXT,
    gueltig_von TEXT,
    gueltig_bis TEXT,
    monitor_link TEXT
  ),
  grain (
    FID
  )
);

SELECT
  *
FROM READ_CSV('zip://seeds/at/*_hst_csv*.zip/steige.csv', quote='"', escape='\')