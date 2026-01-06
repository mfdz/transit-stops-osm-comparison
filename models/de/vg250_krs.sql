MODEL (
  name de.vg250_krs,
  kind FULL,
  cron '@monthly'
);

SELECT
  *
FROM ST_READ('seeds/de/VG250_KRS.shp')