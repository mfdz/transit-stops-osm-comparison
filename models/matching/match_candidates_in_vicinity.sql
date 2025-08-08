MODEL (
  name matching.match_candidates_in_vicinity,
  kind VIEW,
  description ""
);

SELECT
  t.globaleID,
  t.number_of_station_quays,
  o.osm_id,
  ST_DISTANCE(t.projected_geometry, o.projected_geometry) AS distance
FROM matching.transit_stops AS t
JOIN stage.osm_stops AS o
  ON ST_DWITHIN(t.projected_geometry, o.projected_geometry, @MAXIMUM_DISTANCE)