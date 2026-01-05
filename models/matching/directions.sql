MODEL (
  name matching.directions,
  kind FULL
);

SELECT DISTINCT
  succ.routes AS route_short_name,
  t.stop_id AS from_id,
  t.stop_long_name AS from_name,
  t.latitude AS from_lat,
  t.longitude AS from_lon,
  st2.stop_id AS to_id,
  st2.stop_name AS to_name,
  st2.stop_lat AS to_lat,
  st2.stop_lon AS to_lon,
  ST_MAKELINE(
    ST_POINT(from_lon, from_lat),
    ST_POINT(from_lon + (
      to_lon - from_lon
    ) / 8, from_lat + (
      to_lat - from_lat
    ) / 8)
  ) AS geometry
FROM matching.matches_with_state AS t
JOIN stage.gtfs_stops_successors AS succ
  ON succ.predecessor_id = t.stop_id
JOIN gtfs.stops AS st2
  ON succ.successor_id = st2.stop_id
WHERE
  t.match_state = 'MATCHED_THOUGH_REVERSED_DIR'