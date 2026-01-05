MODEL (
  name matching.matches_with_geom_and_state,
  kind FULL,
  physical_properties (
    primary_key = (stop_id, osm_id)
  )
);

SELECT
  m.*,
  ST_MAKELINE(o.projected_geometry, m.projected_geometry) AS line
FROM matching.matches_with_state AS m
JOIN stage.osm_stops AS o
  ON o.osm_id = m.osm_id