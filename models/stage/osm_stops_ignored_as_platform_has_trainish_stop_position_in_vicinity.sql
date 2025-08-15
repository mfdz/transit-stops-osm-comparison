MODEL (
  name stage.osm_stops_ignored_as_platform_has_trainish_stop_position_in_vicinity,
  kind VIEW,
  description "We ignore platforms for trains/lightrails/trams if there is a stop_position with trains/lightrails/trams and identical name or ifopt in the vicinity."
);

SELECT
  h.osm_id
FROM stage.osm_stop_candidates_with_mode_and_type AS h, stage.osm_stop_candidates_with_mode_and_type AS s
WHERE
  h.type = 'platform'
  AND (h.name = s.name OR h.ref=s.ref)
  AND s.type = 'stop'
  AND s.mode IN ('light_rail', 'train', 'tram', 'trainish')
  AND h.mode IN ('light_rail', 'train', 'tram', 'trainish')
  AND s.lat BETWEEN h.lat - 0.01 AND h.lat + 0.01
  AND s.lon BETWEEN h.lon - 0.01 AND h.lon + 0.01