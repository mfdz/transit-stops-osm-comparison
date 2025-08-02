MODEL (
  name stage.osm_platform_ways_with_centroid,
  kind VIEW
);

SELECT
  osm_id,
  CASE
    WHEN ST_GeometryType(geometry)='POLYGON'
    THEN ST_CENTROID(geometry)
    ELSE ST_LINEINTERPOLATEPOINT(geometry, 0.5)
  END AS geometry
FROM (
  SELECT
    *
  FROM stage.osm_platform_ways_with_geom
)