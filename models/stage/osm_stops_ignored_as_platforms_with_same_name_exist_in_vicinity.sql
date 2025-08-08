MODEL (
  name stage.osm_stops_ignored_as_platforms_with_same_name_exist_in_vicinity,
  kind VIEW,
  description "We ignore stop_positions for buses if there is a platform with the same name in the vicinity."
);

SELECT
  h.osm_id
FROM stage.osm_stop_candidates_with_mode_and_type AS h
JOIN stage.osm_stop_candidates_with_mode_and_type AS s
  ON h.name = s.name
  AND s.lat BETWEEN h.lat - 0.01 AND h.lat + 0.01
  AND s.lon BETWEEN h.lon - 0.01 AND h.lon + 0.01
WHERE
  h.type = 'stop' AND s.type = 'platform' AND s.mode = 'bus' AND h.mode = 'bus'