MODEL (
  name stage.osm_platform_ways_with_geom,
  kind VIEW
);

SELECT
  'w'||id osm_id,
  CASE
    WHEN ST_EQUALS(ST_STARTPOINT(linestring), ST_ENDPOINT(linestring))
    THEN ST_MAKEPOLYGON(linestring)
    ELSE linestring
  END AS geometry
FROM (
  SELECT
    pn.id,
    ST_MAKELINE(LIST(pn.geometry ORDER BY ref_idx ASC)) AS linestring
  FROM stage.osm_platform_ways_with_node_geoms AS pn
  GROUP BY
    1
)