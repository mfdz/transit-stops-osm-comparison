MODEL (
  name raw.osm,
  kind VIEW
);

SELECT
  *
FROM ST_READOSM('seeds/'||@TRANSIT_STOPS_SCHEMA||'/data.osm.pbf')