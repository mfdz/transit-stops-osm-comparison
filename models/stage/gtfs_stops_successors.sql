MODEL (
  name stage.gtfs_stops_successors,
  kind FULL
);

SELECT
  predecessor_id,
  successor_id,
  LISTAGG(route_short_name, ', ') AS routes,
  BOOL_AND(is_long_distance) AS is_long_distance
FROM (
  SELECT DISTINCT
    REPLACE(p.stop_id, '_G', '') AS predecessor_id,
    REPLACE(s.stop_id, '_G', '') AS successor_id,
    r.route_short_name,
    CASE
      WHEN route_type IN (100, 101, 102, 103, 106, 200, 201, 202)
      THEN TRUE
      ELSE FALSE
    END AS is_long_distance
  FROM gtfs.stop_times AS p
  JOIN gtfs.stop_times AS s
    ON p.trip_id = s.trip_id AND p.stop_sequence = s.stop_sequence - 1
  JOIN gtfs.trips AS t
    ON p.trip_id = t.trip_id
  JOIN gtfs.routes AS r
    ON t.route_id = r.route_id
)
GROUP BY
  predecessor_id,
  successor_id