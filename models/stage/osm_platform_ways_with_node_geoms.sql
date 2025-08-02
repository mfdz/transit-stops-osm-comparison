MODEL (
  name stage.osm_platform_ways_with_node_geoms,
  kind VIEW
);

SELECT
  pn.*,
  ST_POINT(lon, lat) AS geometry
FROM stage.osm_platform_ways_with_node_refs AS pn
JOIN raw.osm AS o
  ON o.id = pn.ref