MODEL (
  name at.haltestellen,
  kind FULL,
  tags at,
  columns (
    FID TEXT,
    hst_id TEXT,
    hst_name TEXT,
    hst_globid TEXT,
    hst_x DOUBLE,
    hst_y DOUBLE,
    hst_gem_name TEXT,
    umst_agg_vm TEXT,
    umst_agg_max TEXT,
    gis_agg_vm TEXT,
    linien_agg TEXT,
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
FROM READ_CSV('zip://seeds/at/*_hst_csv*.zip/haltestellen.csv', quote='"', escape='\')