MODEL (
  name stage.osm_stops_ignored_as_platform_in_vicinity,
  kind VIEW,
  description "We ignore bus stop_positions where there are bus platforms nearby https://github.com/mfdz/nvbw-osm-stop-comparison/issues/4"
);

SELECT
  s.osm_id
FROM stage.osm_stop_candidates_with_mode_and_type AS s
JOIN stage.osm_stop_candidates_with_mode_and_type AS p
  ON p.lat BETWEEN s.lat - 0.0001 AND s.lat + 0.0001
  AND p.lon BETWEEN s.lon - 0.0001 AND s.lon + 0.0001
WHERE
  s.type = 'stop' AND p.type = 'platform' AND p.mode = 'bus' AND s.mode = 'bus'