MODEL (
  name stage.osm_stops_ignored_as_stop_position_has_bus_platform_in_vicinity,
  kind VIEW,
  description "We ignore stop_positions for buses if there is a platform with the same IFOPT or name in the vicinity."
);

SELECT
  h.osm_id
FROM stage.osm_stop_candidates_with_mode_and_type AS h, stage.osm_stop_candidates_with_mode_and_type AS s
WHERE
  h.type = 'stop'
  AND h.mode = 'bus'
  AND s.type = 'platform'
  AND (
    h.ref = s.ref OR h.name = s.name
  )
  AND s.lat BETWEEN h.lat - 0.01 AND h.lat + 0.01
  AND s.lon BETWEEN h.lon - 0.01 AND h.lon + 0.01