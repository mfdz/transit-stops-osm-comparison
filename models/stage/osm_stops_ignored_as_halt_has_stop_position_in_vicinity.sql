MODEL (
  name stage.osm_stops_ignored_as_halt_has_stop_position_in_vicinity,
  kind VIEW,
  description "We only retain halts/stations where no bus or trams stop in vicinity and with same name exists."
);

SELECT
  h.osm_id
FROM stage.osm_stop_candidates_with_mode_and_type AS h
WHERE
  h.type IN ('halt', 'station')
  AND EXISTS(
    SELECT
      1
    FROM stage.osm_stop_candidates_with_mode_and_type AS s
    WHERE
      h.name = s.name
      AND s.lat BETWEEN h.lat - 0.01 AND h.lat + 0.01
      AND s.lon BETWEEN h.lon - 0.01 AND h.lon + 0.01
      AND s.type IN ('stop', 'platform')
      AND NOT s.mode IN ('bus', 'tram')
  )