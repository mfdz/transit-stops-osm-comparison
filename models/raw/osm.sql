MODEL (
  name raw.osm,
  kind VIEW
);

SELECT
  *
FROM ST_READOSM('seeds/data.osm.pbf')